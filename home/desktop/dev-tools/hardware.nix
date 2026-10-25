{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.dev-tools.hardware;
in
{
  options.my.home.desktop.dev-tools.hardware = {
    enable = mkEnableOption "Hardware development tools (KiCad, Qucs-S, JLCONE, Picocom, etc.)";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      kicad
      picocom
      qucs-s
      ventoy
      nur.repos.mio.jlcone
    ];
  };
}
