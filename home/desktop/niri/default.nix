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
    # Niri configuration is generated as a KDL string (./config.kdl.nix) so
    # the shared palette and the home path stay in sync. niri-flake's typed
    # `programs.niri.settings` does not cover niri v26.04 features such as
    # `blur` / `background-effect`; `programs.niri.config` fully replaces
    # `settings`, so the typed attrset must not be set.
    programs.niri.config = import ./config.kdl.nix {
      inherit palette;
      homeDirectory = config.home.homeDirectory;
    };

    # Essential Wayland tooling
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
