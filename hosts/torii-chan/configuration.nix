{ config, pkgs, lib, inputs, ... }:

let
  username = "t3u";
in
{
  imports = [
    ./disko.nix
  ];

  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.grub.enable = false;

  networking.hostName = "torii-chan";
  networking.networkmanager.enable = true;

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDFX6B7lal7NJA93tBL5Gwg6MPz//rVWFuO06ycTyw6c discharge@BrokenPC"
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDFX6B7lal7NJA93tBL5Gwg6MPz//rVWFuO06ycTyw6c discharge@BrokenPC"
  ];

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  system.stateVersion = "25.05";
}
