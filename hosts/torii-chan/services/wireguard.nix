{ config, pkgs, lib, ... }:

{
  # WireGuard Server Configuration
  
  # 1. Open Firewall
  networking.firewall.allowedUDPPorts = [ 51820 ];

  # 2. Manage Private Key via SOPS
  sops.secrets.torii_chan_wireguard_private_key = {
    # WireGuard needs to read this
    owner = "root";
    mode = "0400";
    # サービス再起動のトリガー
    restartUnits = [ "wireguard-wg0.service" ];
  };

  # 3. Enable IP Forwarding & NAT (Gateway Mode)
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1; # Enable IPv6 forwarding if needed
  };

  networking.nat = {
    enable = true;
    externalInterface = "end0"; # WAN interface
    internalInterfaces = [ "wg0" ];
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
          publicKey = "bd7DKPnKfc7s73oYT3uHP0jM+6TrSvf2nr83Cb6kZhU=";
          allowedIPs = [ "10.0.0.2/32" ];
        }
      ];
    };
  };
}
