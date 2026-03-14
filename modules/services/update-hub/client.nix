{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.my.updateHub.client;
  targetUser = config.users.users.${cfg.user} or { home = "/home/${cfg.user}"; group = cfg.user; };
  flakePath = "${targetUser.home}/${cfg.subdir}";

  # nvfetcher ターゲットの抽出
  nvDirs = concatStringsSep " " (map (t: t.dir) (filter (t: t.enable) cfg.nvfetcher));
  nvConfigs = concatStringsSep " " (map (t: t.configFile) (filter (t: t.enable) cfg.nvfetcher));

  # スクリプトの生成 (パスを scripts/ 配下に修正)
  updateClientScript = pkgs.writeShellScriptBin "nixos-auto-update" (builtins.readFile ./scripts/update-client.sh);
  receiverScript = pkgs.writeScriptBin "nixos-update-receiver" ''
    #!${pkgs.python3}/bin/python3
    ${builtins.readFile ./scripts/receiver.py}
  '';
in {
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

      environment = {
        FLAKE_PATH = flakePath;
        TOKEN_PATH = config.sops.secrets.github_token.path;
        HUB_URL = cfg.hubUrl;
        REMOTE_URL = cfg.remoteUrl;
        HOSTNAME = config.networking.hostName;
        USERNAME = cfg.user;
        GROUPNAME = targetUser.group;
        PUSH_CHANGES = if cfg.pushChanges then "true" else "false";
        USE_BOOT = if cfg.useBoot then "true" else "false";
        GIT_USER_NAME = cfg.gitUserName;
        GIT_USER_EMAIL = cfg.gitUserEmail;
        NVFETCHER_DIRS = nvDirs;
        NVFETCHER_CONFIGS = nvConfigs;
        EXTRA_REBUILD_ARGS = concatStringsSep " " cfg.extraRebuildArgs;
      };

      script = "${updateClientScript}/bin/nixos-auto-update";
    };

    systemd.timers.nixos-auto-update = {
      description = "Timer for NixOS Auto Update";
      timerConfig = {
        OnCalendar = cfg.onCalendar;
        Persistent = true;
      };
      wantedBy = [ "timers.target" ];
    };

    # 通知レシーバー (Webhook)
    systemd.services.nixos-update-trigger = {
      description = "NixOS Update Trigger Receiver";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      path = [ pkgs.systemd ];
      
      postStart = ''
        if [ -d "${flakePath}/.git" ]; then
          ${pkgs.coreutils}/bin/chown -R ${cfg.user}:${targetUser.group} ${flakePath}
          COMMIT=$(${pkgs.git}/bin/git -C ${flakePath} -c safe.directory=${flakePath} rev-parse HEAD)
          ${pkgs.curl}/bin/curl --max-time 5 -sf -X POST \
            -H "Content-Type: application/json" \
            -d "{\"host\": \"${config.networking.hostName}\", \"commit\": \"$COMMIT\", \"timestamp\": \"$(${pkgs.coreutils}/bin/date -Iseconds)\"}" \
            ${cfg.hubUrl}/consumer/reported || true
        fi
      '';

      serviceConfig = {
        ExecStart = "${receiverScript}/bin/nixos-update-receiver 8081";
        Restart = "always";
        User = "root";
      };
    };

    networking.firewall.interfaces.wg1.allowedTCPPorts = [ 8081 ];
  };
}