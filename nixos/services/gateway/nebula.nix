{ config, lib, ... }:

let
  cfg = config.my.services.gateway;
in
{
  config = lib.mkIf cfg.enable {
    my.networking.nebula = {
      enable = true;
      isLighthouse = true;
      isRelay = true;
      extraInbound = [
        {
          port = 22;
          group = "mgmt";
        }
        {
          port = 25565;
          group = "app";
        }
      ];
    };
  };
}
