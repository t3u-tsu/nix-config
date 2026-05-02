{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.gaming;
in
{
  options.my.home.desktop.gaming = {
    enable = mkEnableOption "Gaming tools and optimizations";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      mangohud
      protonup-qt
      heroic
      prismlauncher
      steam-run
      gamescope
    ];
  };
}
