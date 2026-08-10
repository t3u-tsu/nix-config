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
    ../../nixos/profiles/tower-server
    ../../nixos
  ];

  my = {
    services.minecraft.enable = true;
  };

  sops.secrets = {
    minecraft_forwarding_secret = {
      sopsFile = ../../secrets/services/minecraft.yaml;
      owner = "minecraft";
      group = "minecraft";
      mode = "0400";
    };

    nitac23s_rcon_password = {
      sopsFile = ../../secrets/services/minecraft.yaml;
      owner = "minecraft";
      group = "minecraft";
      mode = "0400";
    };

    discord_admin_guild_id = {
      sopsFile = ../../secrets/services/minecraft.yaml;
      owner = "minecraft";
      group = "minecraft";
      mode = "0400";
    };
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

  # Enable local network optimizations (NAT loopback bypass for torii-chan)
  # my.networking.local-network.enable = true;

  # Core i7 870 is x86_64
  # Quadro K2200 (Maxwell) uses standard NVIDIA drivers
  my.hardware.nvidia.enable = true;
}
