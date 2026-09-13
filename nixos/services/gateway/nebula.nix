{ config, lib, ... }:

with lib;

let
  cfg = config.my.services.gateway;
in
{
  config = mkIf cfg.enable {
    my.networking.nebula = {
      enable = true;
      ip = "10.0.0.1";
      groups = [ "mgmt" ];
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
