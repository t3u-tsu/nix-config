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

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
  };
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostId = "c0ffee01";
  networking.hostName = "kagutsuchi-sama";

  # Enable local network optimizations (NAT loopback bypass for torii-chan)
  # my.networking.local-network.enable = true;

  my.hardware.nvidia.enable = true;
}
