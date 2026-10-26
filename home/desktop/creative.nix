{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.home.desktop.creative;
in
{
  options.my.home.desktop.creative = {
    enable = lib.mkEnableOption "Creative tools";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.gimp
      pkgs.obs-studio
      pkgs.blender
    ];
  };
}
