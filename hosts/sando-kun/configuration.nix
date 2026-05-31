{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./disko-config.nix
    ./services
    ../../modules
    ../../modules/profiles/tower-server
  ];

  my.hardware.pc-tools.enable = true;
  # comin deployment service
  my.services.deployment.comin.enable = true;

  # GeForce 8400 GS (Tesla) is too old for modern NVIDIA drivers.
  # We stick with nouveau or basic kernel drivers for stability.

  # Bootloader configuration
  boot.loader.grub = {
    enable = true;
    efiSupport = false; # i7-860 is Legacy BIOS
    # device will be set by disko
  };

  # Networking
  networking.hostId = "5a4d0001";
  networking.hostName = "sando-kun";
  networking.useDHCP = true;

  # Enable local network optimizations (Disabled as default since machines moved LANs)
  # my.localNetwork.enable = true;

  system.stateVersion = "26.05";
}
