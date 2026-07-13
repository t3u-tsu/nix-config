{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  pkgCfg = config.my.packages.monitoring;
in
{
  config = mkIf pkgCfg.enable {
    environment.systemPackages = with pkgs; [
      btop
      duf
      dust
      fastfetch
      htop
      hwinfo
      hwloc
      lm_sensors
      lsof
      pciutils
      procs
      usbutils
    ];
  };
}
