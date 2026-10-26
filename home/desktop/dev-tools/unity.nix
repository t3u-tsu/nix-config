{
  config,
  lib,
  inputs,
  ...
}:

{
  imports = [
    inputs.unity-via-distrobox.homeModules.unity
  ];

  options.my.home.desktop.dev-tools.unity.enable =
    lib.mkEnableOption "Unity development environment via Distrobox";

  config = lib.mkIf config.my.home.desktop.dev-tools.unity.enable {
    my.unity = {
      enable = lib.mkDefault true;
      stopOnExit = true;
      minimizeToTray = false;
    };
  };
}
