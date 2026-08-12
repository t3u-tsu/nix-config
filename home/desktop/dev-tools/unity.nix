{
  config,
  lib,
  inputs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.dev-tools;
in
{
  imports = [
    inputs.unity-via-distrobox.homeModules.unity
  ];

  config = mkIf cfg.enable {
    my.unity = {
      enable = mkDefault true;
      stopOnExit = true;
      minimizeToTray = false;
    };
  };
}
