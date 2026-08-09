# nixos/profiles/gateway/default.nix
#
# Portable "torii-chan" role: a WireGuard VPN gateway + Cloudflare DDNS client
# that forwards Minecraft traffic into the application network (wg1).
#
# This module is intentionally platform-agnostic: it can run on the physical SBC
# (Orange Pi Zero3) OR a VPS, one at a time (failover). The only platform-specific
# knobs are the WAN interface name (`my.services.gateway.wanInterface`) and the
# access-restriction toggle used during SD image provisioning.
#
# Because every peer reaches this host via the public hostname
# `torii-chan.t3u.uk:51820/51821`, takeover is seamless: when the VPS assumes the
# role, its own DDNS updates the A record to the VPS public IP and all peers
# reconnect without reconfiguration. Both machines therefore share the same
# WireGuard keys (see secrets/hosts/torii-chan.yaml).
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
    enable = mkEnableOption "torii-chan role: WireGuard gateway + DDNS + Minecraft forward";

    wanInterface = mkOption {
      type = types.str;
      default = "end0";
      # SBC: end0 (internal GbE). VPS: usually eth0 (adjust to your provider).
      description = "Name of the external / WAN interface used for NAT";
    };

    wireguardPrivateKey = mkOption {
      type = types.str;
      default = "torii_chan_wireguard_private_key";
      description = "SOPS secret key name for the wg0 server private key";
    };

    wireguardAppPrivateKey = mkOption {
      type = types.str;
      default = "torii_chan_wireguard_app_private_key";
      description = "SOPS secret key name for the wg1 server private key";
    };

    restrictAccess = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Tighten the firewall: expose only TCP 25565 (Minecraft) on the WAN and
        allow SSH only via wg0. Set to false (with mkForce) during SD image
        creation so a freshly-booted system stays reachable over LAN SSH for
        initial provisioning.
      '';
    };
  };

  config = mkIf cfg.enable {
    # ------------------------------------------------ base system
    networking = {
      hostName = "torii-chan";

      # Firewall.
      #   - WAN TCP exposure depends on restrictAccess:
      #       * true  -> only 25565 (Minecraft, rate-limited); SSH is wg0-only.
      #       * false -> plain SSH on all interfaces (SD provisioning).
      #   - WireGuard UDP is always allowed.
      #   - wg1 (application network) is trusted: all traffic.
      firewall = {
        enable = true;
        allowedUDPPorts = [
          51820
          51821
        ];
        allowedTCPPorts = if cfg.restrictAccess then lib.mkForce [ ] else [ 22 ];

        # Suppress noisy kernel logs from internet scans (this host is exposed).
        logRefusedConnections = false;
        logReversePathDrops = false;

        interfaces.wg0.allowedTCPPorts = [ 22 ];

        interfaces.wg1 = {
          allowedTCPPortRanges = [
            {
              from = 0;
              to = 65535;
            }
          ];
          allowedUDPPortRanges = [
            {
              from = 0;
              to = 65535;
            }
          ];
        };

        # Extra iptables rules (the firewall uses the iptables backend;
        # networking.nftables.enable is false, so nftables-only options such as
        # extraInputRules are ignored here).
        extraCommands = ''
          # Ensure DNATed traffic to the Minecraft server is masqueraded so the
          # return path is correct.
          iptables -t nat -A POSTROUTING -d 10.0.1.4 -p tcp --dport 25565 -j MASQUERADE
          # Rate-limit the public Minecraft port (WAN exposure, production only).
          ${lib.optionalString cfg.restrictAccess ''
            iptables -A INPUT -p tcp --dport 25565 -m limit --limit 10/sec --limit-burst 20 -j ACCEPT
          ''}
        '';
      };

      # NAT + port forwarding (Minecraft proxy -> shosoin-tan over wg1).
      nat = {
        enable = true;
        externalInterface = cfg.wanInterface; # WAN interface
        internalInterfaces = [
          "wg0"
          "wg1"
        ];
        forwardPorts = [
          {
            proto = "tcp";
            sourcePort = 25565;
            destination = "10.0.1.4:25565";
          }
        ];
      };

      # WireGuard servers. Peer retry is handled by nixos/networking/wireguard.nix.
      wireguard.interfaces = {
        wg0 = {
          # Management network
          ips = [ "10.0.0.1/24" ];
          listenPort = 51820;
          # Optimized MTU for stability over unstable parent links.
          mtu = 1300;
          privateKeyFile = config.sops.secrets.${cfg.wireguardPrivateKey}.path;
          peers = [
            {
              # Management PC
              publicKey = "bd7DKPnKfc7s73oYT3uHP0jM+6TrSvf2nr83Cb6kZhU=";
              allowedIPs = [ "10.0.0.100/32" ];
            }
            {
              # kagutsuchi-sama
              publicKey = "S9Tb8hQQIMDhCuV9Ya3/yodraebnoRwkYXURXpoPxyY=";
              allowedIPs = [ "10.0.0.3/32" ];
            }
            {
              # shosoin-tan
              publicKey = "nTYFHpES11zywOPDkVg5Y9jlsFF6vEg5y8WVFSVHKhg=";
              allowedIPs = [ "10.0.0.4/32" ];
            }
            {
              # sando-kun
              publicKey = "eg7Y3QgbJvefcPJn7FfVIC9hPU4rH8Q2t+qfXBzgd10=";
              allowedIPs = [ "10.0.0.2/32" ];
            }
          ];
        };

        wg1 = {
          # Application communication network
          ips = [ "10.0.1.1/24" ];
          listenPort = 51821;
          mtu = 1300;
          privateKeyFile = config.sops.secrets.${cfg.wireguardAppPrivateKey}.path;
          peers = [
            {
              # kagutsuchi-sama
              publicKey = "VmFDY7RtuAcGC/qKR6qsTn/jWBp9nfIBraLLpi63Jyo=";
              allowedIPs = [ "10.0.1.3/32" ];
            }
            {
              # shosoin-tan (runs the Minecraft proxy + servers)
              publicKey = "qTA8ah+HdiygId07yViqQ/KFsZP51/EV9U8aE7/Jzno=";
              allowedIPs = [ "10.0.1.4/32" ];
            }
            {
              # sando-kun
              publicKey = "4rxYZxUdPbu86bKCwcKwNDYHq4DGN38k0tjG6yhDwCA=";
              allowedIPs = [ "10.0.1.2/32" ];
            }
            {
              # BrokenPC
              publicKey = "VAvwzVJ1dDOy+A2OMFRXEGYe8E3lXJeYki0Z5I635AE=";
              allowedIPs = [ "10.0.1.100/32" ];
            }
          ];
        };
      };
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
          # Limit brute-force attempts (SSH is wg0-only in production, but
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
      ${cfg.wireguardPrivateKey} = {
        owner = "root";
        mode = "0400";
        restartUnits = [ "wireguard-wg0.service" ];
      };
      ${cfg.wireguardAppPrivateKey} = {
        owner = "root";
        mode = "0400";
        restartUnits = [ "wireguard-wg1.service" ];
      };
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
