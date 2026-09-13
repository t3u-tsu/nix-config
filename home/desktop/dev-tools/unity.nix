{
  config,
  lib,
  inputs,
  ...
}:

with lib;
{
  imports = [
    inputs.unity-via-distrobox.homeModules.unity
  ];

  config = mkIf config.my.home.desktop.full.enable {
    my.unity = {
      enable = mkDefault true;
      stopOnExit = true;
      minimizeToTray = false;
    };
  };
}
