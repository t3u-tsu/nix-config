{ config, pkgs, lib, inputs, ... }:

let
  username = "t3u";
in
{

  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.grub.enable = false;

  networking.hostName = "torii-chan";
  networking.networkmanager.enable = true;

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_ROOT";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
  };

  system.stateVersion = "25.05";
}
