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

  my.hardware.nvidia.enable = true;
}
