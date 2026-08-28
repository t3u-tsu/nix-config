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
  ];

  boot.loader.grub = {
    enable = true;
    efiSupport = false;
    device = "/dev/disk/by-id/ata-ST9250320AS_5SW1VK4F";
  };

  networking = {
    hostId = "5a4d0001";
    hostName = "sando-kun";
    useDHCP = true;
  };
}
