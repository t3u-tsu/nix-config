# nixos/networking/nebula.nix
#
# Common Nebula mesh-VPN module (single overlay "nebula0").
#
# Replaces the WireGuard hub-and-spoke design (wg0/wg1) with a full mesh:
#   - network  nebula0, subnet 10.0.2.0/24, UDP 4242 (Lighthouse/Relay only)
#   - torii-chan (10.0.2.1) is the Lighthouse + Relay, advertised via
#     torii-chan.t3u.uk:4242 (DDNS failover between SBC and VPS).
#   - zone separation is done via certificate groups + the Nebula firewall,
#     NOT per-overlay interfaces.
#
# Firewall model (2 layers):
#   - NixOS firewall = physical WAN/LAN ingress control.
#     nebula0 is added to `networking.firewall.trustedInterfaces`, so all
#     in-tunnel traffic is governed by the Nebula firewall instead.
#   - Nebula firewall = in-tunnel control. The common module opens ICMP only;
#     services open their own ports via `extraInbound`.
#
# Secrets (SOPS):
#   - CA certificate (public)  -> secrets/common.yaml
#   - node certificate + key   -> secrets/hosts/<host>.yaml
#
{ config, lib, ... }:

with lib;

let
  # Lowercased hostname (hyphens -> underscores) used for SOPS key mapping.
  hostKey = builtins.replaceStrings [ "-" ] [ "_" ] (lib.toLower config.networking.hostName);

  # systemd user/group created by the NixOS nebula module for this network.
  serviceUser = "nebula-nebula0";
  serviceUnit = "nebula@nebula0.service";

  cfg = config.my.networking.nebula;

  # Convert our convenience extraInbound entries ({port; proto; group|host|cidr})
  # into the raw Nebula firewall rule shape.
  # NOTE: Nebula >=1.10 requires every inbound rule to carry at least one of
  # host/group/cidr/local_cidr/ca_name/ca_sha, so the common ICMP rule pins
  # host = "any" (ICMP is allowed from every peer).
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
      example = "10.0.2.1";
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
      default = "10.0.2.1";
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

      # Certificates (paths resolved from SOPS secrets).
      ca = config.sops.secrets.nebula_ca.path;
      cert = config.sops.secrets."${hostKey}_nebula_cert".path;
      key = config.sops.secrets."${hostKey}_nebula_key".path;

      # Clients report to the Lighthouse; the Lighthouse itself has none.
      lighthouses = optional (!cfg.isLighthouse) cfg.lighthouse;

      # All nodes prefer direct P2P and fall back through the Relay (torii-chan).
      relays = [ cfg.lighthouse ];

      # Clients must know the Lighthouse's real (public) address to reach it.
      # The Lighthouse itself instead advertises via `advertise_addrs`.
      staticHostMap = optionalAttrs (!cfg.isLighthouse) {
        "${cfg.lighthouse}" = cfg.advertiseAddrs;
      };

      # Use the interface name the plan expects (trustedInterfaces / greps).
      tun.device = "nebula0";

      firewall = {
        # Inbound: ICMP by default + per-service rules.
        inbound = inboundRules;
        # Outbound: allow everything (inbound is what gates access).
        outbound = [
          {
            proto = "any";
            port = "any";
            host = "any";
          }
        ];
      };

      # Raw settings merged on top of the generated config.
      settings = {
        inherit (cfg) ip mtu groups;
        pki.blocklist = cfg.blocklist;
      }
      // optionalAttrs cfg.isLighthouse { advertise_addrs = cfg.advertiseAddrs; };
    };

    # All in-tunnel traffic is controlled by the Nebula firewall.
    networking.firewall.trustedInterfaces = [ "nebula0" ];

    # --- SOPS secrets ------------------------------------------------
    sops.secrets = {
      # CA cert (public) — shared by every host.
      nebula_ca = {
        sopsFile = ../../secrets/common.yaml;
        owner = "root";
        group = serviceUser;
        mode = "0440";
        restartUnits = [ serviceUnit ];
      };
      # Node certificate + key (host-specific).
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
