{ config, lib, ... }:
{
  # X1 Carbon Gen 7 ships a single NVMe SSD. The partition layout below is the
  # planned one (ESP + ext4 root); adjust the by-id paths to the real device:
  #   lsblk -o NAME,PATH,UUID   (or `blkid`) to find the by-id names
  # then replace the __REPLACE__ placeholders:
  #   /dev/nvme0n1p1  ESP (vfat, 512MiB)   -> /boot
  #   /dev/nvme0n1p2  Linux (ext4, rest)   -> /
  # Swap uses zram (16GB RAM), so no swap partition is created.
  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-id/__REPLACE_ESP__-part1";
      fsType = "vfat";
    };

    "/" = {
      device = "/dev/disk/by-id/__REPLACE_ROOT__-part2";
      fsType = "ext4";
    };
  };

  swapDevices = [ ];

  zramSwap.enable = true;
}
