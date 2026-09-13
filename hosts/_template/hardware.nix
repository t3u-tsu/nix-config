{ config, lib, ... }:
{
  # Disk layout. Start from `nixos-generate-config --root /mnt --dir /tmp/nixos`
  # and keep only fileSystems / swapDevices, switching device paths to stable
  # by-id names (`lsblk -o NAME,PATH,UUID`). Device-specific tuning belongs in
  # default.nix or in a nixos-hardware profile.
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
