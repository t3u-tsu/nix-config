{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ./disko-config.nix
    ./services
    ../../modules/services/minecraft
    ../../modules/services/backup
    ../../modules/services/discord-bridge
    ../../modules/profiles/tower-server
    ../../modules
  ];

  my.hardware.pc-tools.enable = true;
  my.services.minecraft.enable = true;

  sops.secrets.minecraft_forwarding_secret = {
    owner = "minecraft";
    group = "minecraft";
    mode = "0400";
  };

  sops.secrets.nitac23s_rcon_password = {
    owner = "minecraft";
    group = "minecraft";
    mode = "0400";
  };

  sops.secrets.discord_admin_guild_id = {
    owner = "minecraft";
    group = "minecraft";
    mode = "0400";
  };

  # Bootloader configuration
  boot.loader.grub = {
    enable = true;
    efiSupport = false;
  };

  # ZFS requires a unique hostId
  networking.hostId = "8425e349";
  networking.hostName = "shosoin-tan";
  networking.useDHCP = true;

  # Enable local network optimizations (NAT loopback bypass for torii-chan)
  # my.localNetwork.enable = true;

  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  boot.zfs.extraPools = [ "tank-1tb" ];

  # Core i7 870 is x86_64
  # Quadro K2200 (Maxwell) uses standard NVIDIA drivers
  my.hardware.nvidia.enable = true;

  # comin deployment service
  my.services.deployment.comin.enable = true;
  
  system.stateVersion = "26.05";
}
