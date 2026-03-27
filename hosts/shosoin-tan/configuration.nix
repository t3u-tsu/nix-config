{ config, pkgs, lib, inputs, ... }:

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

  # GT 210 / GT 710 configuration

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

  # Shosoin-tan is the Update Producer
  my.updateHub.client = {
    enable = true;
    pushChanges = true;
  };

  system.stateVersion = "25.05";
}