# hosts/shosoin-tan/hardware.nix - Filesystem and ZFS configuration
{ config, lib, ... }:
{
  # SSD (480GB) - System
  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-id/ata-CT480BX500SSD1_1946E3D7A95A-part2";
      fsType = "vfat";
    };

    "/" = {
      device = "/dev/disk/by-id/ata-CT480BX500SSD1_1946E3D7A95A-part3";
      fsType = "ext4";
    };

    # 320GB HDD - Scratch data
    "/mnt/data-320gb" = {
      device = "/dev/disk/by-id/ata-WDC_WD3200AAJS-98B4A0_WD-WCAT19003074-part1";
      fsType = "ext4";
      options = [
        "defaults"
        "nofail"
      ];
    };
  };

  # ZFS mirror pool (2x 1TB HDD)
  boot.zfs.extraPools = [ "tank-1tb" ];
}
