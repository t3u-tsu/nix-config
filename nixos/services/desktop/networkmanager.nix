{
  config,
  lib,
  ...
}:

let
  cfg = config.my.services.desktop.networkmanager;
in
{
  options.my.services.desktop.networkmanager = {
    enable = lib.mkEnableOption "NetworkManager for desktop network management";
  };

  config = lib.mkIf cfg.enable {
    networking.networkmanager.enable = true;
  };
}
