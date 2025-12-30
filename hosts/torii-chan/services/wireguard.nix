{ config, pkgs, lib, ... }:

{
  # WireGuard Server Configuration
  
  # 1. Open Firewall
  networking.firewall.allowedUDPPorts = [ 51820 51821 ];
  networking.firewall.allowedTCPPorts = [ 25565 ]; # Minecraft

  # 2. Manage Private Keys via SOPS
  sops.secrets.torii_chan_wireguard_private_key = {
    owner = "root";
    mode = "0400";
    restartUnits = [ "wireguard-wg0.service" ];
  };
  sops.secrets.torii_chan_wireguard_app_private_key = {
    owner = "root";
    mode = "0400";
    restartUnits = [ "wireguard-wg1.service" ];
  };

  # 3. Enable IP Forwarding & NAT (Gateway Mode)
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1; # Enable IPv6 forwarding if needed
  };

  networking.nat = {
    enable = true;
    externalInterface = "end0"; # WAN interface
    internalInterfaces = [ "wg0" "wg1" ];
    forwardPorts = [
      {
        proto = "tcp";
        sourcePort = 25565;
        destination = "10.0.1.3:25565";
      }
    ];
    # wg0:
      # WireGuard interface dedicated to host management.
      # SSH and other administrative access are ONLY permitted via this network.
  };

  # 4. WireGuard Interface
  networking.wireguard.interfaces = {
    wg0 = {
      # The IP address and subnet of the server's internal WireGuard interface
      ips = [ "10.0.0.1/24" ];

      # The port that WireGuard listens to.
      listenPort = 51820;

      # Path to the private key file.
      privateKeyFile = config.sops.secrets.torii_chan_wireguard_private_key.path;

      # List of allowed peers.
      peers = [
        {
          # Management PC
          publicKey = "bd7DKPnKfc7s73oYT3uHP0jM+6TrSvf2nr83Cb6kZhU=";
          allowedIPs = [ "10.0.0.100/32" ];
        }
        {
          # kagutsuchi-sama
          publicKey = "S9Tb8hQQIMDhCuV9Ya3/yodraebnoRwkYXURXpoPxyY=";
          allowedIPs = [ "10.0.0.3/32" ];
        }
        {
          # shosoin-tan
          publicKey = "nTYFHpES11zywOPDkVg5Y9jlsFF6vEg5y8WVFSVHKhg=";
          allowedIPs = [ "10.0.0.4/32" ];
        }
        {
          # sando-kun
          publicKey = "eg7Y3QgbJvefcPJn7FfVIC9hPU4rH8Q2t+qfXBzgd10=";
          allowedIPs = [ "10.0.0.2/32" ];
        }
      ];
    };

    wg1 = {
      # Application communication network
      ips = [ "10.0.1.1/24" ];
      listenPort = 51821;
      privateKeyFile = config.sops.secrets.torii_chan_wireguard_app_private_key.path;

      peers = [
        {
          # kagutsuchi-sama
          publicKey = "VmFDY7RtuAcGC/qKR6qsTn/jWBp9nfIBraLLpi63Jyo=";
          allowedIPs = [ "10.0.1.3/32" ];
        }
        {
          # shosoin-tan
          publicKey = "qTA8ah+HdiygId07yViqQ/KFsZP51/EV9U8aE7/Jzno=";
          allowedIPs = [ "10.0.1.4/32" ];
        }
        {
          # sando-kun
          publicKey = "4rxYZxUdPbu86bKCwcKwNDYHq4DGN38k0tjG6yhDwCA=";
          allowedIPs = [ "10.0.1.2/32" ];
        }
      ];
    };
  };
}
