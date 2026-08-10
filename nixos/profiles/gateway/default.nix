# nixos/profiles/gateway/default.nix
#
# Portable "torii-chan" role: a Nebula mesh gateway + Cloudflare DDNS client
# that forwards Minecraft traffic into the application mesh (nebula0).
#
# This module is intentionally platform-agnostic: it can run on the physical SBC
# (Orange Pi Zero3) OR a VPS, one at a time (failover). The only platform-specific
# knobs are the WAN interface name (`my.services.gateway.wanInterface`) and the
# access-restriction toggle used during SD image provisioning.
#
# torii-chan is the single Lighthouse + Relay of the nebula0 overlay
# (10.0.2.0/24). Peers reach it via the public hostname
# `torii-chan.t3u.uk:4242`, so SBC/VPS takeover is seamless: when the VPS
# assumes the role, its own DDNS updates the A record to the VPS public IP and
# all peers reconnect without reconfiguration.
{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.my.services.gateway;
in
{
  options.my.services.gateway = {
    enable = mkEnableOption "torii-chan role: Nebula gateway + DDNS + Minecraft forward";

    wanInterface = mkOption {
      type = types.str;
      default = "end0";
      # SBC: end0 (internal GbE). VPS: usually eth0 (adjust to your provider).
      description = "Name of the external / WAN interface used for NAT";
    };

    restrictAccess = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Tighten the firewall: expose only TCP 25565 (Minecraft) on the WAN and
        allow SSH only via the Nebula mesh (nebula0). Set to false (with
        mkForce) during SD image creation so a freshly-booted system stays
        reachable over LAN SSH for initial provisioning.
      '';
    };
  };

  config = mkIf cfg.enable {
    # ------------------------------------------------ base system
    networking = {
      hostName = "torii-chan";

      # Firewall.
      #   - WAN TCP exposure depends on restrictAccess:
      #       * true  -> only 25565 (Minecraft, rate-limited); SSH is Nebula-only.
      #       * false -> plain SSH on all interfaces (SD provisioning).
      #   - UDP 4242 (Nebula Lighthouse/Relay) is added automatically by the
      #     services.nebula module.
      #   - nebula0 (mesh) is trusted; in-tunnel control is the Nebula firewall.
      firewall = {
        enable = true;
        allowedTCPPorts = if cfg.restrictAccess then lib.mkForce [ ] else [ 22 ];

        # Suppress noisy kernel logs from internet scans (this host is exposed).
        logRefusedConnections = false;
        logReversePathDrops = false;

        # Extra iptables rules (the firewall uses the iptables backend;
        # networking.nftables.enable is false, so nftables-only options such as
        # extraInputRules are ignored here).
        extraCommands = ''
          # Ensure DNATed traffic to the Minecraft server is masqueraded so the
          # return path is correct.
          iptables -t nat -A POSTROUTING -d 10.0.2.4 -p tcp --dport 25565 -j MASQUERADE
          # Rate-limit the public Minecraft port (WAN exposure, production only).
          ${lib.optionalString cfg.restrictAccess ''
            iptables -A INPUT -p tcp --dport 25565 -m limit --limit 10/sec --limit-burst 20 -j ACCEPT
          ''}
        '';
      };

      # NAT + port forwarding (Minecraft proxy -> shosoin-tan over nebula0).
      nat = {
        enable = true;
        externalInterface = cfg.wanInterface; # WAN interface
        # Nebula is a full mesh (P2P); no outbound NAT over the overlay is
        # needed. Only the Minecraft port-forward (with the MASQUERADE above)
        # applies.
        internalInterfaces = lib.mkForce [ ];
        forwardPorts = [
          {
            proto = "tcp";
            sourcePort = 25565;
            destination = "10.0.2.4:25565";
          }
        ];
      };
    };

    # ------------------------------------------------ Nebula mesh VPN
    # torii-chan is the single Lighthouse + Relay for the nebula0 overlay.
    # Placing it in the shared gateway profile (used by both the SBC and the
    # failover VPS) makes Lighthouse failover seamless: DDNS advertises
    # `torii-chan.t3u.uk:4242` and all peers reconnect without reconfiguration.
    my.networking.nebula = {
      enable = true;
      ip = "10.0.2.1";
      groups = [ "mgmt" ];
      isLighthouse = true;
      isRelay = true;
      extraInbound = [
        # SSH (management).
        {
          port = 22;
          group = "mgmt";
        }
        # Minecraft DNAT return path (Phase 3, when forwarding moves to nebula).
        {
          port = 25565;
          group = "app";
        }
      ];
    };

    # Request sudo password by default (Production Security).
    # Overridden (mkForce false) only during initial SD image creation.
    security.sudo.wheelNeedsPassword = true;

    services = {
      openssh = {
        enable = true;
        ports = [ 22 ];
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;

          # --- hardening ---
          # Limit brute-force attempts (SSH is Nebula-only in production, but
          # defense in depth on the LAN/provisioning path).
          MaxAuthTries = 3;
          LoginGraceTime = 30;
          ClientAliveInterval = 60;
          ClientAliveCountMax = 3;
          AllowUsers = [
            "root"
            config.my.user.name
          ];
        };
      };

      # DDNS: lightweight Go implementation (favonia/cloudflare-ddns).
      cloudflare-ddns = {
        enable = true;
        credentialsFile = config.sops.secrets.cloudflare_api_env.path;
        detectionTimeout = "15s";

        # Update only IPv4 (A records).
        ip4Domains = [
          "torii-chan.t3u.uk"
          "mc.t3u.uk"
          "*.mc.t3u.uk"
        ];
        ip6Domains = [ ];

        domains = [
          "torii-chan.t3u.uk"
          "mc.t3u.uk"
          "*.mc.t3u.uk"
        ];
      };
    };

    # ------------------------------------------------ secrets (SOPS)
    sops.secrets = {
      cloudflare_api_env = {
        sopsFile = ../../../secrets/services/ddns.yaml;
        owner = "root";
        # Restart the service automatically when the secret changes.
        restartUnits = [ "cloudflare-ddns.service" ];
      };
    };

    # ------------------------------------------------ IP forwarding
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;

      # --- kernel hardening ---
      # Restrict kernel pointer / dmesg visibility to root.
      "kernel.kptr_restrict" = 2;
      "kernel.dmesg_restrict" = 1;
      # Disable unprivileged BPF and harden the JIT compiler.
      "kernel.unprivileged_bpf_disabled" = 1;
      "net.core.bpf_jit_harden" = 2;
      # Reverse-path filtering + disable ICMP redirect handling (mitigate
      # spoofing / redirect-based attacks on this internet-exposed gateway).
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
    };

    # Explicitly disable IPv6 detection to avoid timeouts on slow links.
    systemd.services.cloudflare-ddns.serviceConfig.Environment = [
      "IP6_PROVIDER=none"
    ];
  };
}
