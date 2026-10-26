{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.services.desktop.thunar;
in
{
  options.my.services.desktop.thunar = {
    enable = lib.mkEnableOption "Thunar file manager";
  };

  config = lib.mkIf cfg.enable {
    programs = {
      thunar = {
        enable = true;
        plugins = with pkgs; [
          thunar-archive-plugin
          thunar-volman
        ];
      };

      xfconf.enable = true;
    };

    services = {
      gvfs.enable = true;
      tumbler.enable = true;
    };
  };
}
