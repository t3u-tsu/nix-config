{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.services.emergencySsh;
in
{
  options.my.services.emergencySsh = {
    enable = lib.mkEnableOption "Cloudflare Tunnel emergency SSH access";
  };

  config = lib.mkIf cfg.enable {
    systemd.services.cloudflared-emergency-ssh = {
      description = "Cloudflare Tunnel for emergency SSH";
      after = [
        "network.target"
        "network-online.target"
      ];
      wants = [
        "network.target"
        "network-online.target"
      ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        DynamicUser = true;
        Restart = "always";
        RestartSec = "5s";
        LoadCredential = [
          "token:${config.sops.secrets."${config.my.hostKey}_cloudflared_ssh_token".path}"
        ];
        ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token-file %d/token";
      };
    };

    sops.secrets."${config.my.hostKey}_cloudflared_ssh_token" = { };

    environment.etc."ssh/cloudflare_ca.pub".text = ''
      ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBAtJPFOS2FnrhSJBXk5eU6qsXlQ0G8vYqlNTxQUy7hLzjMoaVDZbNwrwZ2ApBl+mmYX6LR/sTIGb1rqjCCyPIME= open-ssh-ca@cloudflareaccess.org
    '';

    services.openssh.settings = {
      TrustedUserCAKeys = "/etc/ssh/cloudflare_ca.pub";
      AuthorizedPrincipalsCommand = "${pkgs.writeShellScript "emergency-ssh-principals" ''
        case "$1" in
          ${config.my.user.name})
            echo "${config.my.user.name}"
            echo "${config.my.user.name}@t3u.uk"
            ;;
        esac
      ''} %u";
      AuthorizedPrincipalsCommandUser = "nobody";
      Macs = [
        "hmac-sha2-512-etm@openssh.com"
        "hmac-sha2-256-etm@openssh.com"
        "umac-128-etm@openssh.com"
        "hmac-sha2-256"
        "hmac-sha2-512"
      ];
    };
  };
}
