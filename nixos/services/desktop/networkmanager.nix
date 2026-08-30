{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.my.services.desktop.networkmanager;
in
{
  options.my.services.desktop.networkmanager = {
    enable = mkEnableOption "NetworkManager for desktop network management";
  };

  config = mkIf cfg.enable {
    networking.networkmanager.enable = true;
  };
}
