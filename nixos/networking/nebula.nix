# Nebula mesh-VPN module
#   - network  nebula0, subnet 10.0.0.0/24, UDP 4242 (Lighthouse/Relay only)
#   - torii-chan (10.0.0.1) is the Lighthouse + Relay, advertised via
#     torii-chan.t3u.uk:4242 (DDNS failover between SBC and VPS).

{ config, lib, ... }:

with lib;

let
  # Lowercased hostname (hyphens -> underscores) used for SOPS key mapping.
  hostKey = builtins.replaceStrings [ "-" ] [ "_" ] (lib.toLower config.networking.hostName);

  serviceUser = "nebula-nebula0";
  serviceUnit = "nebula@nebula0.service";

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
    // optionalAttrs (r.group != null) { groups = [ r.group ]; }
    // optionalAttrs (r.host != null) { inherit (r) host; }
    // optionalAttrs (r.cidr != null) { inherit (r) cidr; }
  ) cfg.extraInbound;
in
{
  options.my.networking.nebula = {
    enable = mkEnableOption "Nebula mesh VPN (nebula0)";

    ip = mkOption {
      type = types.str;
      default = "";
      example = "10.0.0.1";
      description = "Nebula IP of this node (must be within the CA network).";
    };

    groups = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "mgmt" ];
      description = "Nebula groups this node belongs to (zone separation).";
    };

    mtu = mkOption {
      type = types.int;
      default = 1320;
      description = ''
        Common tun MTU for ALL nodes. In a P2P mesh the sender's tun MTU sets the
        packet size, so every node must agree. 1320 = min path MTU 1380 - 60 (Nebula).
        Boundary value; confirm with `ping -M do` on mobile in Phase 2, drop to 1300
        if unstable.
      '';
    };

    isLighthouse = mkOption {
      type = types.bool;
      default = false;
      description = "Whether this node is a Lighthouse (torii-chan).";
    };

    isRelay = mkOption {
      type = types.bool;
      default = false;
      description = "Whether this node is a Relay (torii-chan).";
    };

    lighthouse = mkOption {
      type = types.str;
      default = "10.0.0.1";
      description = "Nebula IP of the Lighthouse (torii-chan).";
    };

    advertiseAddrs = mkOption {
      type = types.listOf types.str;
      default = [ "torii-chan.t3u.uk:4242" ];
      description = ''
        Addresses the Lighthouse advertises to clients (used to establish P2P).
        SBC/VPS failover is seamless: DDNS points the hostname at the active
        public IP, so peers reconnect without reconfiguration.
      '';
    };

    blocklist = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Revoked certificate fingerprints (pki.blocklist). Apply manually to all hosts.";
    };

    extraInbound = mkOption {
      description = "Extra inbound Nebula firewall rules (services deployed on this host).";
      default = [ ];
      type = types.listOf (
        types.submodule {
          options = {
            port = mkOption {
              type = types.port;
              description = "Destination port.";
            };
            proto = mkOption {
              type = types.enum [
                "tcp"
                "udp"
                "any"
              ];
              default = "tcp";
              description = "Protocol.";
            };
            group = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Allow only from the given Nebula group.";
            };
            host = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Allow only from this Nebula IP.";
            };
            cidr = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Allow only from this CIDR.";
            };
          };
        }
      );
    };
  };

  config = mkIf cfg.enable {
    services.nebula.networks.nebula0 = {
      enable = true;
      inherit (cfg) isLighthouse isRelay;

      ca = config.sops.secrets.nebula_ca.path;
      cert = config.sops.secrets."${hostKey}_nebula_cert".path;
      key = config.sops.secrets."${hostKey}_nebula_key".path;

      lighthouses = optional (!cfg.isLighthouse) cfg.lighthouse;

      relays = [ cfg.lighthouse ];

      staticHostMap = optionalAttrs (!cfg.isLighthouse) {
        "${cfg.lighthouse}" = cfg.advertiseAddrs;
      };

      tun.device = "nebula0";

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
      }
      // optionalAttrs cfg.isLighthouse { advertise_addrs = cfg.advertiseAddrs; };
    };

    networking.firewall.trustedInterfaces = [ "nebula0" ];

    sops.secrets = {
      nebula_ca = {
        sopsFile = ../../secrets/common.yaml;
        owner = "root";
        group = serviceUser;
        mode = "0440";
        restartUnits = [ serviceUnit ];
      };
      "${hostKey}_nebula_cert" = {
        owner = "root";
        group = serviceUser;
        mode = "0440";
        restartUnits = [ serviceUnit ];
      };
      "${hostKey}_nebula_key" = {
        owner = "root";
        group = serviceUser;
        mode = "0440";
        restartUnits = [ serviceUnit ];
      };
    };
  };
}
