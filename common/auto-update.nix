{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.my.autoUpdate;
  # システム設定から指定ユーザーのホームディレクトリを解決
  targetUser = config.users.users.${cfg.user};
  flakePath = "${targetUser.home}/${cfg.subdir}";
in {
  options.my.autoUpdate = {
    enable = mkEnableOption "Automatic system and plugin updates";
    user = mkOption {
      type = types.str;
      default = "t3u";
      description = "The user who owns the nix-config repository";
    };
    subdir = mkOption {
      type = types.str;
      default = "nix-config";
      description = "Subdirectory under home for the repository";
    };
    remoteUrl = mkOption {
      type = types.str;
      default = "github.com/t3u-tsu/nix-config.git";
    };
    gitUserName = mkOption {
      type = types.str;
      default = "t3u-daemon";
    };
    gitUserEmail = mkOption {
      type = types.str;
      default = "t3u+daemon@t3u.uk";
    };
    pushChanges = mkOption {
      type = types.bool;
      default = false;
      description = "Whether this host should update flake.lock and push changes to Git";
    };
    onCalendar = mkOption {
      type = types.str;
      default = "*-*-* 04:00:00";
      description = "Systemd OnCalendar expression for the update timer";
    };
    hubUrl = mkOption {
      type = types.str;
      default = "http://10.0.1.1:8080";
      description = "URL of the update-hub on torii-chan";
    };
    nvfetcher = mkOption {
      type = types.listOf (types.submodule {
        options = {
          enable = mkEnableOption "Enable nvfetcher for this target";
          dir = mkOption {
            type = types.str;
            description = "Directory containing nvfetcher.toml (relative to flake root)";
          };
          configFile = mkOption {
            type = types.str;
            default = "nvfetcher.toml";
            description = "Name of the nvfetcher config file";
          };
        };
      });
      default = [];
      description = "List of nvfetcher targets to update";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.github_token.owner = "root";

    systemd.services.nixos-auto-update = {
      description = "NixOS Auto Update Service";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      
      path = with pkgs; [ nix git openssh coreutils nvfetcher nixos-rebuild gnused curl ];

      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };

      script = ''
        export NIX_CONFIG="extra-experimental-features = nix-command flakes"
        TOKEN=$(cat ${config.sops.secrets.github_token.path})
        HUB="${cfg.hubUrl}"
        HOSTNAME="${config.networking.hostName}"
        
        # リポジトリの準備
        if [ ! -d "${flakePath}/.git" ]; then
          echo "Preparing repository at ${flakePath}..."
          mkdir -p "${flakePath}"
          rm -rf "${flakePath}"
          git clone "https://x-access-token:$TOKEN@${cfg.remoteUrl}" "${flakePath}"
          chown -R ${cfg.user}:${targetUser.group} "${flakePath}"
        fi

        cd "${flakePath}"

        # 現在のローカル状態
        git fetch origin main
        LOCAL_COMMIT=$(git rev-parse origin/main)

        if [ "${if cfg.pushChanges then "true" else "false"}" = "true" ]; then
          # --- Producer Mode ---
          echo "Producer mode: Updating and pushing changes..."
          git reset --hard origin/main
          nix flake update
          
          # nvfetcher の実行
          ${lib.concatMapStringsSep "\n" (target: lib.optionalString target.enable ''
            echo "Running nvfetcher in ${target.dir}..."
            if [ -d "${target.dir}" ]; then
              (cd "${target.dir}" && nvfetcher -c "${target.configFile}")
            else
              echo "Warning: Directory ${target.dir} does not exist. Skipping nvfetcher."
            fi
          '') cfg.nvfetcher}

          # Git操作
          git -c user.name="${cfg.gitUserName}" -c user.email="${cfg.gitUserEmail}" add .
          if ! git diff --cached --exit-code; then
            git -c user.name="${cfg.gitUserName}" -c user.email="${cfg.gitUserEmail}" commit -m "chore(auto): update system and plugins $(date +%F)"
            git push "https://x-access-token:$TOKEN@${cfg.remoteUrl}" main
          fi
          
          NEW_COMMIT=$(git rev-parse HEAD)
          # ハブに通知
          curl -X POST -d "{\"commit\": \"$NEW_COMMIT\"}" "$HUB/producer/done"
          
          # 自分自身も更新
          nixos-rebuild switch --flake .
        else
          # --- Consumer Mode ---
          echo "Consumer mode: Checking hub for updates..."
          HUB_COMMIT=$(curl -s "$HUB/latest-commit")
          
          if [ -z "$HUB_COMMIT" ]; then
             echo "Hub has no commit info. Skipping update."
             exit 0
          fi

          if [ "$LOCAL_COMMIT" = "$HUB_COMMIT" ]; then
             echo "System is already up to date with hub ($HUB_COMMIT). Skipping."
          else
             echo "New update found: $HUB_COMMIT. Applying..."
             git reset --hard "$HUB_COMMIT"
             nixos-rebuild switch --flake .
          fi

          # ハブに結果を報告
          CURRENT_COMMIT=$(git rev-parse HEAD)
          TIMESTAMP=$(date -Iseconds)
          curl -X POST -d "{\"host\": \"$HOSTNAME\", \"commit\": \"$CURRENT_COMMIT\", \"timestamp\": \"$TIMESTAMP\"}" "$HUB/consumer/reported"
        fi
      '';
    };

    systemd.timers.nixos-auto-update = {
      description = "Timer for NixOS Auto Update";
      timerConfig = {
        OnCalendar = cfg.onCalendar;
        Persistent = true;
      };
      wantedBy = [ "timers.target" ];
    };
  };
}
