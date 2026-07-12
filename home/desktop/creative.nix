{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.creative;
in
{
  options.my.home.desktop.creative = {
    enable = mkEnableOption "Creative tools";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      gimp
      obs-studio
    ];
  };
}
