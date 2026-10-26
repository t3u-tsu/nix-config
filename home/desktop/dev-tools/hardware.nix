{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.home.desktop.dev-tools.hardware;
in
{
  options.my.home.desktop.dev-tools.hardware = {
    enable = lib.mkEnableOption "Hardware development tools (KiCad, Qucs-S, JLCONE, Picocom, etc.)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.kicad
      pkgs.picocom
      pkgs.qucs-s
      pkgs.ventoy
      pkgs.nur.repos.mio.jlcone
    ];
  };
}
