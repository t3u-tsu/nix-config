{ config, lib, ... }:

let
  cfg = config.my.services.desktop.bluetooth;
in
{
  options.my.services.desktop.bluetooth = {
    enable = lib.mkEnableOption "Bluetooth (bluez daemon, power-on at boot)";

    experimental = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Opt in to bluez experimental features (LE Audio and related profiles).
        Changing this requires restarting `bluetooth.service` (restartIfChanged
        is disabled upstream so a plain switch does not apply it).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings.General.Experimental = cfg.experimental;
    };
  };
}
