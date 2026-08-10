{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./hardware.nix
    ./services
    ../../nixos
    ../../nixos/profiles/tower-server
  ];

  # GeForce 8400 GS (Tesla) is too old for modern NVIDIA drivers.
  # We stick with nouveau or basic kernel drivers for stability.

  boot.loader.grub = {
    enable = true;
    efiSupport = false; # i7-860 is Legacy BIOS
    device = "/dev/disk/by-id/ata-ST9250320AS_5SW1VK4F";
  };

  # Networking
  networking = {
    hostId = "5a4d0001";
    hostName = "sando-kun";
    useDHCP = true;
  };

  # Enable local network optimizations (Disabled as default since machines moved LANs)
  # my.networking.local-network.enable = true;
}
