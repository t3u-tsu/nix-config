{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  username = "t3u";
in
{
  nixpkgs.overlays = [
  ];

  imports = [
    ./services
    ../../nixos
    ../../nixos/profiles/sbc
  ];

  boot.loader = {
    generic-extlinux-compatible.enable = true;
    grub.enable = false;
  };

  networking = {
    hostName = "torii-chan";
    # networking.networkmanager.enable = true; # Using static config below
    useDHCP = false;

    interfaces.end0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "192.168.0.128";
          prefixLength = 24;
        }
      ];
      macAddress = "36:43:64:11:45:14";
    };

    defaultGateway = "192.168.0.1";
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      logRefusedConnections = false;
      logReversePathDrops = false;
    };
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
}
