{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.my.home.desktop.media;
in {
  options.my.home.desktop.media = {
    enable = mkEnableOption "Media players and entertainment tools";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      vlc
      spotify
    ];
  };
}
