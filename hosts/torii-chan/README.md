# Host: torii-chan (Nebula Gateway / Lighthouse & Relay)

Edge gateway deployed at Site T on an Orange Pi Zero 3 SBC (`192.168.0.128`), with automated failover to ConoHa VPS.

## Hardware Specifications

| Component | Specification | Details |
| :--- | :--- | :--- |
| **SoC** | Allwinner H618 | Quad-core ARM Cortex-A53 up to 1.5 GHz |
| **RAM** | 1 GB LPDDR4 | Shared memory |
| **Storage (Production)** | 2.5" SATA HDD via USB bridge | Root filesystem (`/dev/disk/by-label/NIXOS_HDD`) |
| **Storage (Bootloader)** | MicroSD Card | U-Boot SPL and boot partition |
| **Network** | Gigabit Ethernet (1000BASE-T) | Static local IP: `192.168.0.128` |

## Roles & Network Architecture

- **Primary Lighthouse & Relay:** Central discovery node and mesh traffic relay for Nebula (`10.0.0.1:4242`).
- **Cloudflare DDNS:** Dynamic IP sync daemon updating `torii-chan.t3u.uk`, `mc.t3u.uk`, and `*.mc.t3u.uk`.
- **Minecraft Port Forward:** Proxies public `tcp/25565` traffic to `shosoin-tan` (`10.0.0.4:25565`) across the Nebula overlay.
- **Security Boundary:** SSH port 22 is restricted to `nebula0`. UDP `4242` (Nebula) and TCP `25565` (Minecraft) are exposed publicly.
- **Failover Compatibility:** Shares hostname and SOPS secrets with `torii-chan-vps` for automated failover.

## Flake Configurations

| Target | Architecture | Target Medium / Purpose |
| :--- | :--- | :--- |
| `torii-chan-hdd` | `aarch64-linux` | Production SBC deployment (Root on USB SATA HDD) |
| `torii-chan-sd` | `aarch64-linux` | Production SBC deployment (Root on MicroSD) |
| `torii-chan-vps` | `x86_64-linux` | Failover deployment on ConoHa VPS (512MB) |
| `torii-chan-sd-installer` | `aarch64-linux` | Minimal SD installer image |
| `torii-chan-vps-iso` | `x86_64-linux` | Minimal rescue installer ISO |

## Quick Operations

```bash
# Rebuild SBC remotely (disabling sandbox on 1GB RAM)
nixos-rebuild switch \
  --flake .#torii-chan-hdd \
  --target-host t3u@10.0.0.1 \
  --sudo --ask-sudo-password \
  --option sandbox false \
  --option filter-syscalls false
```

## References

- Hardware architecture, U-Boot, and storage: [`docs/hardware/orange-pi-zero3.md`](../../docs/hardware/orange-pi-zero3.md)
- ConoHa VPS failover & failback runbook: [`docs/operations/vps-failover.md`](../../docs/operations/vps-failover.md)
- Network topology: [`docs/architecture/network-topology.md`](../../docs/architecture/network-topology.md)
- Host addition runbook: [`docs/operations/adding-a-host.md`](../../docs/operations/adding-a-host.md)
