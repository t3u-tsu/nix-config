# Gateway Services (`nixos/services/gateway/`)

Network routing and gateway services for the `torii-chan` role, shared between the physical SBC and failover VPS.

## Services Architecture

| Module | Role & Responsibilities |
| :--- | :--- |
| [`firewall.nix`](firewall.nix) | WAN firewall restricting exposed traffic to TCP 25565 (Minecraft proxy) with iptables/nftables NAT MASQUERADE rules. |
| [`hardening.nix`](hardening.nix) | Linux kernel sysctl hardening (`kptr_restrict`, `dmesg_restrict`, BPF JIT, `rp_filter`, ICMP redirects). |
| [`nebula.nix`](nebula.nix) | Nebula Lighthouse & Relay configuration (`10.0.0.1:4242`) with inbound rules for management and application traffic. |
| [`ssh.nix`](ssh.nix) | Key-only OpenSSH daemon on the `nebula0` overlay interface; [`firewall.nix`](firewall.nix) blocks WAN access. |
| [`ddns.nix`](ddns.nix) | Cloudflare DDNS client (`ddclient`) dynamically updating `torii-chan.t3u.uk`, `mc.t3u.uk`, and `*.mc.t3u.uk`. |
| [`default.nix`](default.nix) | Service aggregator enabled via `my.services.gateway.enable`. |

## Network Forwarding & Port Map

| Port / Protocol | Inbound Interface | Destination | Description |
| :--- | :--- | :--- | :--- |
| **UDP 4242** | WAN (`end0`) | Localhost (`torii-chan`) | Nebula Lighthouse discovery and relay traffic |
| **TCP 25565** | WAN (`end0`) | `10.0.0.4:25565` (`shosoin-tan`) | Public Minecraft reverse proxy forwarding |
| **TCP 22** | Mesh (`nebula0`) | Localhost (`torii-chan`) | Administrative SSH access (blocked on WAN) |

## References

- Hardware guide (Orange Pi Zero 3): [`docs/hardware/orange-pi-zero3.md`](../../../docs/hardware/orange-pi-zero3.md)
- Failover runbook (ConoHa VPS): [`docs/operations/vps-failover.md`](../../../docs/operations/vps-failover.md)
- Network topology: [`docs/architecture/network-topology.md`](../../../docs/architecture/network-topology.md)
- Host configuration: [`hosts/torii-chan/`](../../../hosts/torii-chan/README.md)
