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

  # Bootloader configuration (Using GRUB to match shosoin-tan)
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # Unique hostId for future ZFS support
  networking.hostId = "c0ffee01";
  networking.hostName = "kagutsuchi-sama";

  # Enable local network optimizations (NAT loopback bypass for torii-chan)
  # my.networking.local-network.enable = true;

  # GTX 980 Ti (Maxwell) configuration
  my.hardware.nvidia.enable = true;
}
