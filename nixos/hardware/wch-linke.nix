{ lib, config, ... }:

with lib;
let
  cfg = config.my.hardware.dev-tools.wch-linke;
in
{
  options.my.hardware.dev-tools.wch-linke = {
    enable = mkEnableOption "WCH-LinkE programming/debugging udev rules";
  };

  config = mkIf cfg.enable {
    services.udev.extraRules = ''
      # WCH-LinkE in RISC-V mode
      SUBSYSTEM=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="8010", GROUP="dialout", MODE="0660"

      # WCH-LinkE in ARM mode
      SUBSYSTEM=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="8012", GROUP="dialout", MODE="0660"
    '';
  };
}
