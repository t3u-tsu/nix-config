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
    ../../nixos/services/minecraft
    ../../nixos/services/backup
    ../../nixos/services/discord-bridge
    ../../nixos/profiles/tower-server
    ../../nixos
  ];

  my.hardware.pc-tools.enable = true;
  my.services.minecraft.enable = true;

  sops.secrets.minecraft_forwarding_secret = {
    sopsFile = ../../secrets/services/minecraft.yaml;
    owner = "minecraft";
    group = "minecraft";
    mode = "0400";
  };

  sops.secrets.nitac23s_rcon_password = {
    sopsFile = ../../secrets/services/minecraft.yaml;
    owner = "minecraft";
    group = "minecraft";
    mode = "0400";
  };

  sops.secrets.discord_admin_guild_id = {
    sopsFile = ../../secrets/services/minecraft.yaml;
    owner = "minecraft";
    group = "minecraft";
    mode = "0400";
  };

  # Bootloader configuration
  boot.loader.grub = {
    enable = true;
    efiSupport = false;
    device = "/dev/disk/by-id/ata-CT480BX500SSD1_1946E3D7A95A";
  };

  # ZFS requires a unique hostId
  networking.hostId = "8425e349";
  networking.hostName = "shosoin-tan";
  networking.useDHCP = true;

  # Enable local network optimizations (NAT loopback bypass for torii-chan)
  # my.localNetwork.enable = true;

  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;

  # Core i7 870 is x86_64
  # Quadro K2200 (Maxwell) uses standard NVIDIA drivers
  my.hardware.nvidia.enable = true;

  system.stateVersion = "26.05";
}
