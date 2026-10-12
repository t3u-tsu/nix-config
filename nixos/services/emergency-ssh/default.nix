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
      ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBIHsq7F3PQTDg/TsWn/hG9+igYbGgtT6En3qRnj0tH3SuzQHqkaRsaGHO0JE+FmFlZy0fnKgiDL/dwz/XIPAiLA= open-ssh-ca@cloudflareaccess.org
    '';

    environment.etc."ssh/auth_principals/${config.my.user.name}".text = ''
      ${config.my.user.name}
    '';

    services.openssh.settings = {
      TrustedUserCAKeys = "/etc/ssh/cloudflare_ca.pub";
      AuthorizedPrincipalsFile = "/etc/ssh/auth_principals/%u";
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
