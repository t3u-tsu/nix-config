{ config, lib, ... }:
{
  # Disk layout. Generate a starting point with:
  #   nixos-generate-config --root /mnt --dir /tmp/nixos
  # then copy the fileSystems / swapDevices sections here and adjust device
  # paths to stable by-id names (lsblk -o NAME,PATH,UUID) as done in the other
  # hosts. Keep hardware.nix limited to storage and firmware concerns;
  # device-specific tuning lives in default.nix or a nixos-hardware profile.
  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-id/...-part1";
      fsType = "vfat";
    };

    "/" = {
      device = "/dev/disk/by-id/...-part2";
      fsType = "ext4";
    };
  };

  swapDevices = [ ];
}
