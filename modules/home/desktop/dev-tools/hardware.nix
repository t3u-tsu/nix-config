{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.my.home.desktop.dev-tools.hardware;
in {
  options.my.home.desktop.dev-tools.hardware = {
    enable = mkEnableOption "Hardware development tools (KiCad, Picocom, etc.)";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      kicad # Electronic Design Automation
      picocom # Serial terminal for hardware debugging
    ];
  };
}
