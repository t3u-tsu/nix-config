{ config, lib, ... }:

let
  cfg = config.my.dev-tools.wch-linke;
in
{
  options.my.dev-tools.wch-linke = {
    enable = lib.mkEnableOption "WCH-LinkE programming/debugging udev rules";
  };

  config = lib.mkIf cfg.enable {
    services.udev.extraRules = ''
      SUBSYSTEM=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="8010", GROUP="dialout", MODE="0660"
      SUBSYSTEM=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="8012", GROUP="dialout", MODE="0660"
    '';
  };
}
