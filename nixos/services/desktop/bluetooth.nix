{ config, lib, ... }:

with lib;
let
  cfg = config.my.services.desktop.bluetooth;
in
{
  options.my.services.desktop.bluetooth = {
    enable = mkEnableOption "Bluetooth (bluez daemon, power-on at boot)";

    experimental = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Opt in to bluez experimental features (LE Audio and related profiles).
        Changing this requires restarting `bluetooth.service` (restartIfChanged
        is disabled upstream so a plain switch does not apply it).
      '';
    };
  };

  config = mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings.General.Experimental = cfg.experimental;
    };
  };
}
