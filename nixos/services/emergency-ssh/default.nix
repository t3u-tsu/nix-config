{
  config,
  lib,
  ...
}:

let
  cfg = config.my.services.emergencySsh;
in
{
  options.my.services.emergencySsh = {
    enable = lib.mkEnableOption "Cloudflare Tunnel emergency SSH access";

    tunnelId = lib.mkOption {
      type = lib.types.str;
      description = "Cloudflare Tunnel UUID";
    };

    hostname = lib.mkOption {
      type = lib.types.str;
      default = "${config.networking.hostName}-cf-ssh.t3u.uk";
      description = "Public hostname routed to the local SSH daemon";
    };
  };

  config = lib.mkIf cfg.enable {
    services.cloudflared = {
      enable = true;
      tunnels.${cfg.tunnelId} = {
        credentialsFile = config.sops.secrets."${config.my.hostKey}_cloudflared_credentials".path;
        ingress = {
          "${cfg.hostname}" = "ssh://localhost:22";
        };
        default = "http_status:404";
      };
    };

    sops.secrets."${config.my.hostKey}_cloudflared_credentials" = {
      key = "${config.my.hostKey}_cloudflared_credentials_json";
    };

    environment.etc."ssh/cloudflare_ca.pub".text = ''
      ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBIHsq7F3PQTDg/TsWn/hG9+igYbGgtT6En3qRnj0tH3SuzQHqkaRsaGHO0JE+FmFlZy0fnKgiDL/dwz/XIPAiLA= open-ssh-ca@cloudflareaccess.org
    '';

    environment.etc."ssh/auth_principals/${config.my.user.name}".text = ''
      ${config.my.user.name}
    '';

    services.openssh.settings = {
      TrustedUserCAKeys = "/etc/ssh/cloudflare_ca.pub";
      AuthorizedPrincipalsFile = "/etc/ssh/auth_principals/%u";
    };
  };
}
