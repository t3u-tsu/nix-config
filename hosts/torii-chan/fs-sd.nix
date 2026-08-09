{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Auto-repair the root filesystem on boot (remote host without physical
  # access; recovers from ext4 inconsistency after an abrupt power loss).
  boot.kernelParams = [ "fsck.repair=yes" ];

  # File systems configuration for SD Card operation
  # Based on the default partition layout of the SD image

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    # Add noatime to reduce writes and extend SD card lifespan.
    options = [ "noatime" ];
  };

  fileSystems."/boot/firmware" = {
    device = "/dev/disk/by-label/FIRMWARE";
    fsType = "vfat";
    # Matches the default fstab generated on the SD image
    options = [
      "nofail"
      "noauto"
    ];
  };
}
