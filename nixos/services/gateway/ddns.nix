{ config, lib, ... }:

let
  cfg = config.my.services.gateway;
in
{
  config = lib.mkIf cfg.enable {
    services.ddclient = {
      enable = true;
      protocol = "cloudflare";
      username = "token";
      zone = "t3u.uk";
      usev4 = "webv4, webv4=ipify-ipv4";
      usev6 = "";
      interval = "5min";
      domains = [
        "torii-chan.t3u.uk"
        "mc.t3u.uk"
        "*.mc.t3u.uk"
      ];
      extraConfig = "password_env=CLOUDFLARE_API_TOKEN";
    };

    age.secrets.cloudflare_api_env = {
      rekeyFile = ../../../secrets/master/services/ddns/cloudflare_api.env.age;
    };

    # systemd reads EnvironmentFile as PID 1, so the root-owned secret does not
    # need to be readable by ddclient's DynamicUser.
    systemd.services.ddclient.serviceConfig.EnvironmentFile = [
      config.age.secrets.cloudflare_api_env.path
    ];
  };
}
