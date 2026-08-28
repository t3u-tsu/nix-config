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
      };

      nat = {
        enable = true;
        externalInterface = cfg.wanInterface;
        internalInterfaces = lib.mkForce [ ];
        # MASQUERADE return traffic from the Minecraft backend (shosoin-tan).
        # Replaces the former hand-written iptables POSTROUTING rule.
        internalIPs = [ "10.0.0.4" ];
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
