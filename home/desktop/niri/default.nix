{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.niri;
  palette = import ../../../lib/palette.nix;

  # The cast-target ring needs a darker shade of palette.err so it still reads
  # as the same warning while inactive; it is not part of the Vesper palette.
  templateVars = {
    background = palette.bg;
    error = palette.err;
    inherit (palette) primary low;
    cast-inactive = "#7d0d2d";
    home-directory = config.home.homeDirectory;
    cursor-theme = config.my.home.desktop.theme.cursor.name;
    cursor-size = toString config.my.home.desktop.theme.cursor.size;
  };
  templateVarNames = builtins.attrNames templateVars;
  placeholders = map (name: "@${name}@") templateVarNames;
  replacements = map (name: templateVars.${name}) templateVarNames;
in
{
  options.my.home.desktop.niri = {
    enable = mkEnableOption "Niri scrollable-tiling Wayland compositor";
  };

  config = mkIf cfg.enable {
    # niri-flake's typed `programs.niri.settings` does not cover niri v26.04
    # features such as `blur` / `background-effect`, and `programs.niri.config`
    # fully replaces it, so the `@name@` placeholders in config.kdl are the only
    # source of truth. niri-flake runs `niri validate` on the result at build time.
    programs.niri.config = builtins.replaceStrings placeholders replacements (
      builtins.readFile ./config.kdl
    );

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
