{ config, lib, ... }:

with lib;

let
  cfg = config.my.services.gateway;
in
{
  config = mkIf cfg.enable {
    networking = {
      hostName = "torii-chan";

      firewall = {
        enable = true;
        allowedTCPPorts = if cfg.restrictAccess then lib.mkForce [ ] else [ 22 ];
        logRefusedConnections = false;
        logReversePathDrops = false;
        extraCommands = ''
          iptables -t nat -A POSTROUTING -d 10.0.0.4 -p tcp --dport 25565 -j MASQUERADE
          ${lib.optionalString cfg.restrictAccess ''
            iptables -A INPUT -p tcp --dport 25565 -m limit --limit 10/sec --limit-burst 20 -j ACCEPT
          ''}
        '';
      };

      nat = {
        enable = true;
        externalInterface = cfg.wanInterface;
        internalInterfaces = lib.mkForce [ ];
        forwardPorts = [
          {
            proto = "tcp";
            sourcePort = 25565;
            destination = "10.0.0.4:25565";
          }
        ];
      };
    };

    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
  };
}
