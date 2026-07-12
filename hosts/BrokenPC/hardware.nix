# hosts/BrokenPC/hardware.nix - Filesystem and boot configuration
{ config, lib, ... }:
{
  # NVMe SSD (512GB) - System
  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-id/nvme-MTFDKBA512TFH-1BC1AABHA_UMDMC01ZRH9LRX-part1";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };

    "/" = {
      device = "/dev/disk/by-id/nvme-MTFDKBA512TFH-1BC1AABHA_UMDMC01ZRH9LRX-part3";
      fsType = "ext4";
    };

    # NVMe SSD (1TB) - Data / Games
    "/data" = {
      device = "/dev/disk/by-id/nvme-FIKWOT_FN500_1TB_AA000000000000000188-part1";
      fsType = "ext4";
      options = [ "nofail" ];
    };
  };

  swapDevices = [
    {
      device = "/dev/disk/by-id/nvme-MTFDKBA512TFH-1BC1AABHA_UMDMC01ZRH9LRX-part2";
      discardPolicy = "both";
    }
  ];
}
