# Networking Modules (`nixos/networking/`)

Network mesh routing, firewall policies, and local DNS optimizations.

## Modules

| File | Purpose | Key Options |
| :--- | :--- | :--- |
| [nebula.nix](nebula.nix) | Mesh VPN daemon (`services.nebula.networks.nebula0`) connecting all fleet hosts (`10.0.0.0/24`). Configures firewall trust for `nebula0`. | `my.networking.nebula.*` |
| [local-network.nix](local-network.nix) | LAN DNS rewrite mapping `torii-chan.t3u.uk` to local IP `192.168.0.128` when communicating within the Site T subnet. | `my.networking.local-network.enable` |
| [default.nix](default.nix) | Networking module aggregator. | — |

## References

- Network topology & Nebula IP allocations: [docs/architecture/network-topology.md](../../docs/architecture/network-topology.md)
- Network disaster recovery: [docs/troubleshooting/network-recovery.md](../../docs/troubleshooting/network-recovery.md)
