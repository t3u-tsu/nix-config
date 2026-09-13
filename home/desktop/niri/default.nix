{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.niri;
  palette = import ../palette.nix;
in
{
  options.my.home.desktop.niri = {
    enable = mkEnableOption "Niri scrollable-tiling Wayland compositor";
  };

  config = mkIf cfg.enable {
    # niri-flake's typed `programs.niri.settings` does not cover niri v26.04
    # features such as `blur` / `background-effect`, and `programs.niri.config`
    # fully replaces it, so the KDL string below is the only source of truth.
    programs.niri.config = import ./config.kdl.nix {
      inherit palette;
      homeDirectory = config.home.homeDirectory;
      cursorTheme = config.my.home.desktop.theme.cursor.name;
      cursorSize = config.my.home.desktop.theme.cursor.size;
    };

    home.packages = with pkgs; [
      xwayland-satellite
      wl-clipboard
      wl-mirror
      jq
      loupe
      grim
      slurp
      adwaita-icon-theme
    ];
  };
}
