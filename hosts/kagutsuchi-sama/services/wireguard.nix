{ config, pkgs, ... }:

{
  # WireGuard Client Configuration for kagutsuchi-sama
  
  sops.secrets.kagutsuchi_sama_wireguard_private_key = {
    owner = "root";
    mode = "0400";
    restartUnits = [ "wireguard-wg0.service" ];
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
  };
}
