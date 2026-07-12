# hosts/kagutsuchi-sama/hardware.nix - Filesystem and boot configuration
{ config, lib, ... }:
{
  # SSD (500GB) - System
  fileSystems."/boot" = {
    device = "/dev/disk/by-id/ata-CT500MX500SSD1_2138E5D3C631-part1";
    fsType = "vfat";
  };

  fileSystems."/" = {
    device = "/dev/disk/by-id/ata-CT500MX500SSD1_2138E5D3C631-part2";
    fsType = "ext4";
  };

  # 3TB HDD - Data
  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-id/ata-WDC_WD30EZRX-19D8PB0_WD-WCC4N1VRD00K-part1";
    fsType = "ext4";
    options = [ "nofail" ];
  };
}
