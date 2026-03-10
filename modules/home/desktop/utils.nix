{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.my.home.desktop.utils;
in {
  options.my.home.desktop.utils = {
    enable = mkEnableOption "Desktop utility tools";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      bitwarden-desktop
      vlc
      spotify
      mangohud
    ];
  };
}
