{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.dev-tools.unity;
in
{
  options.my.home.desktop.dev-tools.unity = {
    enable = mkEnableOption "Unity Hub and development tools";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      unityhub
    ];
  };
}
