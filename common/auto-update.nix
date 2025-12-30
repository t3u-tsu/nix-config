{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.my.autoUpdate;
in {
  options.my.autoUpdate = {
    enable = mkEnableOption "Automatic system and plugin updates";
    flakePath = mkOption {
      type = types.str;
      description = "Absolute path to the nix-config repository";
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
    # GitHub Token の取得設定
    sops.secrets.github_token = {
      owner = "root";
    };

    systemd.services.nixos-auto-update = {
      description = "NixOS Auto Update, Flake Update, and Minecraft Plugins Sync";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        WorkingDirectory = cfg.flakePath;
      };
      path = with pkgs; [
        nix
        git
        openssh
        coreutils
        gnugrep
        gnused
        nvfetcher
        nixos-rebuild
      ];
      script = ''
        export NIX_CONFIG="extra-experimental-features = nix-command flakes"
        
        # 1. Nix Flake の更新 (nixpkgs 等)
        nix flake update

        # 2. nvfetcher によるプラグイン更新
        nvfetcher -c services/minecraft/plugins/nvfetcher.toml -o services/minecraft/plugins

        # 3. 変更があればコミット
        git config user.name "${cfg.gitUserName}"
        git config user.email "${cfg.gitUserEmail}"
        
        git add .
        if ! git diff --cached --exit-code; then
          git commit -m "chore(auto): update system and plugins $(date +%F)"
          
          # 4. GitHub へ Push (Token を使用)
          GITHUB_TOKEN=$(cat ${config.sops.secrets.github_token.path})
          # リモートURLからドメイン部分を抽出して認証情報を埋め込む
          REMOTE_URL=$(git remote get-url origin | sed 's|https://||')
          git push "https://x-access-token:$GITHUB_TOKEN@$REMOTE_URL" main
        fi

        # 5. システムに反映 (再起動を含む)
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
