{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.niri;
in
{
  options.my.home.desktop.niri = {
    enable = mkEnableOption "Niri scrollable-tiling Wayland compositor";
  };

  config = mkIf cfg.enable {
    # Niri configuration lives in a raw KDL file (./config.kdl): niri-flake's
    # typed `programs.niri.settings` does not cover niri v26.04 features such as
    # `blur` / `background-effect`. `programs.niri.config` fully replaces
    # `settings`, so the typed attrset must not be set.
    programs.niri.config = builtins.readFile ./config.kdl;

    # Essential Wayland tooling
    home.packages = with pkgs; [
      xwayland-satellite
      wl-clipboard
      wl-mirror
      loupe
      grim
      slurp
      adwaita-icon-theme
      hyprpolkitagent
    ];
  };
}
