{ config, pkgs, ... }:

{
  # WireGuard Client Configuration for BrokenPC

  sops.secrets.brokenpc_wireguard_private_key = {
    sopsFile = ../../../secrets/services/wireguard.yaml;
    owner = "root";
    mode = "0400";
    restartUnits = [ "wireguard-wg0.service" ];
  };

  sops.secrets.brokenpc_wireguard_app_private_key = {
    sopsFile = ../../../secrets/services/wireguard.yaml;
    owner = "root";
    mode = "0400";
    restartUnits = [ "wireguard-wg1.service" ];
  };

  networking.wireguard.interfaces = {
    wg0 = {
      # Management Network
      ips = [ "10.0.0.100/32" ];
      mtu = 1300;
      privateKeyFile = config.sops.secrets.brokenpc_wireguard_private_key.path;

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
      # Application Network
      ips = [ "10.0.1.100/32" ];
      mtu = 1300;
      privateKeyFile = config.sops.secrets.brokenpc_wireguard_app_private_key.path;

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
