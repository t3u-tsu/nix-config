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
  };

  config = mkIf cfg.enable {
    sops.secrets.github_token.owner = "root";

    systemd.services.nixos-auto-update = {
      description = "NixOS Auto Update Service";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      
      path = with pkgs; [ nix git openssh coreutils nvfetcher nixos-rebuild gnused ];

      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };

      script = ''
        export NIX_CONFIG="extra-experimental-features = nix-command flakes"
        TOKEN=$(cat ${config.sops.secrets.github_token.path})
        
        # リポジトリの準備
        if [ ! -d "${flakePath}/.git" ]; then
          echo "Preparing repository at ${flakePath}..."
          mkdir -p "${flakePath}"
          rm -rf "${flakePath}"
          git clone "https://x-access-token:$TOKEN@${cfg.remoteUrl}" "${flakePath}"
          chown -R ${cfg.user}:${targetUser.group} "${flakePath}"
        fi

        cd "${flakePath}"

        # 念のため、最新の状態であることを確認 (他からのプッシュを取り込む)
        git fetch origin main
        git reset --hard origin/main

        # 更新処理
        nix flake update
        
        # nvfetcher の実行 (設定ファイルのディレクトリで実行して削除を防ぐ)
        (cd services/minecraft/plugins && nvfetcher -c nvfetcher.toml)

        # Git操作
        git -c user.name="${cfg.gitUserName}" -c user.email="${cfg.gitUserEmail}" add .
        if ! git diff --cached --exit-code; then
          git -c user.name="${cfg.gitUserName}" -c user.email="${cfg.gitUserEmail}" commit -m "chore(auto): update system and plugins $(date +%F)"
          git push "https://x-access-token:$TOKEN@${cfg.remoteUrl}" main
        fi

        # 反映
        nixos-rebuild switch --flake .
      '';
    };

    systemd.timers.nixos-auto-update = {
      description = "Timer for NixOS Auto Update";
      timerConfig = {
        OnCalendar = "*-*-* 04:00:00";
        Persistent = true;
      };
      wantedBy = [ "timers.target" ];
    };
  };
}
