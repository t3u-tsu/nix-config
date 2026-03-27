{ pkgs, lib, config, ... }:

with lib;
let
  cfg = config.my.home.desktop.niri;
in {
  config = mkIf cfg.enable {
    # Clipboard History
    services.cliphist.enable = true;

    # Additional GUI tools
    home.packages = with pkgs; [
      nautilus
      loupe
      adwaita-icon-theme
      hyprpolkitagent
    ];
  };
}
