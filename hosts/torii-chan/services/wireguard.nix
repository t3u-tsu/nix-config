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

  # 3. WireGuard Interface
  networking.wireguard.interfaces = {
    wg0 = {
      # The IP address and subnet of the server's internal WireGuard interface
      ips = [ "10.100.0.1/24" ];

      # The port that WireGuard listens to.
      listenPort = 51820;

      # Path to the private key file.
      privateKeyFile = config.sops.secrets.torii_chan_wireguard_private_key.path;

      # List of allowed peers.
      peers = [
        # Example Peer (You can add real peers later)
        # { 
        #   publicKey = "CLIENT_PUBLIC_KEY";
        #   allowedIPs = [ "10.100.0.2/32" ];
        # }
      ];
    };
  };
}
