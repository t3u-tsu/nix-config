{ config, lib, ... }:

let
  cfg = config.my.services.gateway;
in
{
  config = lib.mkIf cfg.enable {
    security.sudo.wheelNeedsPassword = true;

    services.openssh = {
      enable = true;
      ports = [ 22 ];
      openFirewall = !cfg.restrictAccess;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        MaxAuthTries = 3;
        LoginGraceTime = 30;
        ClientAliveInterval = 60;
        ClientAliveCountMax = 3;
        AllowUsers = [
          config.my.user.name
        ];
      };
    };
  };
}
