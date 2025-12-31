{ config, pkgs, ... }:

{
  # WireGuard Client Configuration for kagutsuchi-sama
  
  # Allow application traffic on wg1
  networking.firewall.interfaces.wg1.allowedTCPPortRanges = [ { from = 0; to = 65535; } ];
  networking.firewall.interfaces.wg1.allowedUDPPortRanges = [ { from = 0; to = 65535; } ];

  sops.secrets.kagutsuchi_sama_wireguard_private_key = {
    owner = "root";
    mode = "0400";
    restartUnits = [ "wireguard-wg0.service" ];
  };

  sops.secrets.kagutsuchi_sama_wireguard_app_private_key = {
    owner = "root";
    mode = "0400";
    restartUnits = [ "wireguard-wg1.service" ];
  };

  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "10.0.0.3/24" ];
      privateKeyFile = config.sops.secrets.kagutsuchi_sama_wireguard_private_key.path;

      peers = [
        {
          # torii-chan (Server)
          publicKey = "EuIuhxwOFi5pJeOmdLrrWzkTq4RN+kgyS9yU6mlxGjk=";
          allowedIPs = [ "10.0.0.0/24" ];
          endpoint = "torii-chan.t3u.uk:51820";
          persistentKeepalive = 25;
        }
      ];
    };

    wg1 = {
      ips = [ "10.0.1.3/24" ];
      privateKeyFile = config.sops.secrets.kagutsuchi_sama_wireguard_app_private_key.path;

      peers = [
        {
          # torii-chan (Server)
          publicKey = "uVfr6UKqxTgArzD2lr60wd1DJ9+7WVhxgPnVT4Dj/X8=";
          allowedIPs = [ "10.0.1.0/24" ];
          endpoint = "torii-chan.t3u.uk:51821";
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
