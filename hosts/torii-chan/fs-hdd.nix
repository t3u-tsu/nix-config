{ config, lib, pkgs, ... }:

{
  # Filesystem configuration for HDD operation.
  # Prerequisites:
  # 1. USB HDD/SSD is connected.
  # 2. An ext4 partition with label "NIXOS_HDD" exists on the HDD.
  # 3. System data (at least /nix) has been copied from SD card to HDD.

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_HDD";
    fsType = "ext4";
    # Ensure this is mounted early during boot (especially for USB storage).
    neededForBoot = true;
  };

  # Mount the original SD card root partition as /boot.
  # This ensures kernel updates are written to the SD card where U-Boot can find them.
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };
}