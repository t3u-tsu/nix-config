# nebula0: subnet 10.0.0.0/24, UDP 4242 on the Lighthouse/Relay (torii-chan).
# The Lighthouse is advertised as torii-chan.t3u.uk:4242; DDNS failover between the
# SBC and the VPS lets peers reconnect without reconfiguration.

{ config, lib, ... }:

let
  networkName = "nebula0";
  serviceUser = "nebula-${networkName}";

  cfg = config.my.networking.nebula;

  inboundRules = [
    {
      proto = "icmp";
      port = "any";
      host = "any";
    }
  ]
  ++ map (
    r:
    {
      inherit (r) proto port;
    }
    // lib.optionalAttrs (r.group != null) { groups = [ r.group ]; }
    // lib.optionalAttrs (r.host != null) { inherit (r) host; }
    // lib.optionalAttrs (r.cidr != null) { inherit (r) cidr; }
  ) cfg.extraInbound;
in
{
  options.my.networking.nebula = {
    enable = lib.mkEnableOption "Nebula mesh VPN (nebula0)";

    ip = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "10.0.0.1";
      description = "Nebula IP of this node (must be within the CA network).";
    };

    groups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "mgmt" ];
      description = "Nebula groups this node belongs to (zone separation).";
    };

    mtu = lib.mkOption {
      type = lib.types.int;
      default = 1320;
      description = ''
        Common tun MTU for ALL nodes. In a P2P mesh the sender's tun MTU sets the
        packet size, so every node must agree. 1320 = min path MTU 1380 - 60 (Nebula).
        Boundary value: confirm with `ping -M do` over mobile links and drop to
        1300 if unstable.
      '';
    };

    isLighthouse = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this node is a Lighthouse (torii-chan).";
    };

    isRelay = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this node is a Relay (torii-chan).";
    };

    lighthouse = lib.mkOption {
      type = lib.types.str;
      default = "10.0.0.1";
      description = "Nebula IP of the Lighthouse (torii-chan).";
    };

    advertiseAddrs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "torii-chan.t3u.uk:4242" ];
      description = ''
        Addresses the Lighthouse advertises to clients (used to establish P2P).
        SBC/VPS failover is seamless: DDNS points the hostname at the active
        public IP, so peers reconnect without reconfiguration.
      '';
    };

    blocklist = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Revoked certificate fingerprints (pki.blocklist). Apply manually to all hosts.";
    };

    extraInbound = lib.mkOption {
      description = "Extra inbound Nebula firewall rules (services deployed on this host).";
      default = [ ];
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            port = lib.mkOption {
              type = lib.types.port;
              description = "Destination port.";
            };
            proto = lib.mkOption {
              type = lib.types.enum [
                "tcp"
                "udp"
                "any"
              ];
              default = "tcp";
              description = "Protocol.";
            };
            group = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Allow only from the given Nebula group.";
            };
            host = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Allow only from this Nebula IP.";
            };
            cidr = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Allow only from this CIDR.";
            };
          };
        }
      );
    };
  };

  config = lib.mkIf cfg.enable {
    services.nebula.networks.${networkName} = {
      enable = true;
      inherit (cfg) isLighthouse isRelay;

      # Node and CA certificates are public; only the node key is secret.
      ca = ./nebula/ca.crt;
      cert = ../../hosts/${config.networking.hostName}/nebula.crt;
      key = config.age.secrets.nebula_key.path;

      lighthouses = lib.optional (!cfg.isLighthouse) cfg.lighthouse;

      relays = lib.optional (!cfg.isRelay) cfg.lighthouse;

      staticHostMap = lib.optionalAttrs (!cfg.isLighthouse) {
        "${cfg.lighthouse}" = cfg.advertiseAddrs;
      };

      tun.device = networkName;

      listen = {
        host = "[::]";
        port = 4242;
      };

      firewall = {
        inbound = inboundRules;
        outbound = [
          {
            proto = "any";
            port = "any";
            host = "any";
          }
        ];
      };

      settings = {
        inherit (cfg) ip groups;
        tun.mtu = cfg.mtu;
        pki.blocklist = cfg.blocklist;
        punchy = {
          punch = true;
          respond = true;
        };
      }
      // lib.optionalAttrs cfg.isLighthouse { advertise_addrs = cfg.advertiseAddrs; };
    };

    networking.firewall.trustedInterfaces = [ networkName ];

    age.secrets.nebula_key = {
      rekeyFile = ../../secrets/master/hosts/${config.networking.hostName}/nebula_key.age;
      group = serviceUser;
      mode = "0440";
    };
  };
}
