{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.services.desktop.thunar;
in
{
  options.my.services.desktop.thunar = {
    enable = mkEnableOption "Thunar file manager";
  };

  config = mkIf cfg.enable {
    programs = {
      thunar = {
        enable = true;
        plugins = with pkgs; [
          thunar-archive-plugin
          thunar-volman
        ];
      };

      xfconf.enable = true; # Required for Thunar settings persistence
    };

    services = {
      gvfs.enable = true; # Required for file manager features (Trash, Mounts)
      tumbler.enable = true; # Required for file manager thumbnails
    };
  };
}
