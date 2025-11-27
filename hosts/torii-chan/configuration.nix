{ config, pkgs, lib, inputs, ... }:

let
  username = "t3u";
in
{
  imports = [
    ./disko.nix
  ];

  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";

  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  sops.secrets.t3u_password_hash = {
    neededForUsers = true;
  };

  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.grub.enable = false;

  networking.hostName = "torii-chan";
  # networking.networkmanager.enable = true; # Using static config below

  networking.interfaces.end0 = {
    ipv4.addresses = [{
      address = "192.168.0.128";
      prefixLength = 24;
    }];
    macAddress = "02:00:63:9d:fd:24";
  };

  networking.defaultGateway = "192.168.0.1";
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 42540 ];
  };

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPasswordFile = config.sops.secrets.t3u_password_hash.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3QNRSxPauISsWs7nob0tXfxjTsMpBEIYIjasRD9bpT t3u@BrokenPC"
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3QNRSxPauISsWs7nob0tXfxjTsMpBEIYIjasRD9bpT t3u@BrokenPC"
  ];

  services.openssh = {
    enable = true;
    ports = [ 42540 ];
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  system.stateVersion = "25.05";
}
