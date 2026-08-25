{ config, lib, ... }:

with lib;

let
  cfg = config.my.services.gateway;
in
{
  config = mkIf cfg.enable {
    my.user.authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3QNRSxPauISsWs7nob0tXfxjTsMpBEIYIjasRD9bpT t3u@BrokenPC"
    ];

    security.sudo.wheelNeedsPassword = true;

    services.openssh = {
      enable = true;
      ports = [ 22 ];
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        MaxAuthTries = 3;
        LoginGraceTime = 30;
        ClientAliveInterval = 60;
        ClientAliveCountMax = 3;
        AllowUsers = [
          "root"
          config.my.user.name
        ];
      };
    };
  };
}
