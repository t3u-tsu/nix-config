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
  imports = [
    ./settings.nix
    ./binds.nix
  ];

  options.my.home.desktop.niri = {
    enable = mkEnableOption "Niri scrollable-tiling Wayland compositor";
  };

  config = mkIf cfg.enable {
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
