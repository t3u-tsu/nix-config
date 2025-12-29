{ config, pkgs, lib, inputs, ... }:

let
  username = "t3u";
in
{
  nixpkgs.overlays = [
  ];

  imports = [
    ./services
  ];

  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";

  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  sops.age.sshKeyPaths = [ ];
  sops.age.generateKey = false;

  environment.variables = {
    SOPS_AGE_KEY_FILE = "/var/lib/sops-nix/key.txt";
  };

  sops.secrets.torii_chan_t3u_password_hash = {
    neededForUsers = true;
  };
  sops.secrets.torii_chan_root_password_hash = {
    neededForUsers = true;
  };

  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.grub.enable = false;

  networking.hostName = "torii-chan";
  # networking.networkmanager.enable = true; # Using static config below
  networking.useDHCP = false;

  networking.interfaces.end0 = {
    useDHCP = false;
    ipv4.addresses = [{
      address = "192.168.0.128";
      prefixLength = 24;
    }];
    macAddress = "36:43:64:11:45:14";
  };

  networking.defaultGateway = "192.168.0.1";
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  users.mutableUsers = false;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPasswordFile = config.sops.secrets.torii_chan_t3u_password_hash.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3QNRSxPauISsWs7nob0tXfxjTsMpBEIYIjasRD9bpT t3u@BrokenPC"
    ];
  };

  users.users.root = {
    hashedPasswordFile = config.sops.secrets.torii_chan_root_password_hash.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3QNRSxPauISsWs7nob0tXfxjTsMpBEIYIjasRD9bpT t3u@BrokenPC"
    ];
  };

  # Request password for sudo by default (Production Security)
  # This is disabled only during initial SD image creation in sd-image-installer.nix (mkForce false)
  security.sudo.wheelNeedsPassword = true;

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  system.stateVersion = "25.05";

  nix.settings.trusted-users = [ "root" "t3u" ];
}
