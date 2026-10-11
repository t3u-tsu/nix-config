{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ./hardware.nix
    ./services
  ];

  my = {
    services.minecraft.enable = true;
  };

  boot = {
    loader.grub = {
      enable = true;
      efiSupport = false;
      device = "/dev/disk/by-id/ata-CT480BX500SSD1_1946E3D7A95A";
    };
    supportedFilesystems = [ "zfs" ];
    zfs.forceImportRoot = false;
  };

  networking = {
    hostId = "8425e349";
    hostName = "shosoin-tan";
    useDHCP = true;
  };

  # Direct LAN DNS override when collocated on the same router as torii-chan
  # my.networking.local-network.enable = true;

  my.hardware.nvidia.enable = true;
}
