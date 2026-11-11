# Host: torii-chan (Nebula Gateway / Lighthouse & Relay)

Edge gateway deployed at Site T on an Orange Pi Zero 3 SBC (`192.168.0.128`), with failover support.

## Hardware Specifications

| Component | Specification | Details |
| :--- | :--- | :--- |
| **SoC** | Allwinner H618 | Quad-core ARM Cortex-A53 up to 1.5 GHz |
| **RAM** | 1 GB LPDDR4 | Shared memory |
| **Storage (Production)** | 2.5" SATA HDD via USB bridge | Root filesystem (`/dev/disk/by-label/NIXOS_HDD`) |
| **Storage (Bootloader)** | MicroSD Card | U-Boot SPL and boot partition |
| **Network** | Gigabit Ethernet (1000BASE-T) | Static local IP: `192.168.0.128` |

## Roles & Network Architecture

- Serves as the central discovery lighthouse and mesh traffic relay for Nebula (`10.0.0.1:4242`).
- Runs Cloudflare DDNS to synchronize `torii-chan.t3u.uk`, `mc.t3u.uk`, and `*.mc.t3u.uk` with the edge dynamic IP.
- Forwards public `tcp/25565` traffic (DNAT) to `shosoin-tan` (`10.0.0.4:25565`) across the Nebula overlay.
- Restricts SSH access (port 22) to `nebula0` while publicly exposing UDP `4242` (Nebula) and TCP `25565` (Minecraft).
- Shares hostname and agenix secrets with the failover node.

## Configuration Summary

| Property | Value |
| :--- | :--- |
| **Profile** | `gateway` |
| **Bootloader** | U-Boot SPL on MicroSD, root on USB SATA HDD or MicroSD |
| **Nebula Mesh** | `10.0.0.1` (lighthouse & relay, groups: `mgmt`) |
| **Key Services** | Nebula lighthouse & relay, Cloudflare DDNS, `tcp/25565` DNAT forwarding to `shosoin-tan` |

## Host Modules & Architecture Files

| File | Description | Target / Role |
| :--- | :--- | :--- |
| [default.nix](default.nix) | Shared gateway host definition (host key, emergency SSH); platform wiring comes from the modules selected in [flake/hosts.nix](../../flake/hosts.nix). | Shared by gateway targets |
| [sbc.nix](sbc.nix) | Hardware platform layer for Orange Pi Zero 3 (U-Boot, static LAN IP). | `torii-chan-hdd`, `torii-chan-sd` |
| [fs-hdd.nix](fs-hdd.nix) | Filesystem declarations for USB SATA HDD root deployment. | `torii-chan-hdd` |
| [fs-sd.nix](fs-sd.nix) | Filesystem declarations for MicroSD root deployment. | `torii-chan-sd` |
| [gcp.nix](gcp.nix) | GCE platform layer for Google Cloud on-demand failover (GRUB, DHCP, swap). | `torii-chan-gcp` |
| [sd-installer.nix](sd-installer.nix) | Minimal bootstrap installer definition for Orange Pi Zero 3. | `torii-chan-sd-installer` |
| [installer-common.nix](installer-common.nix) | Common SSH keys and networking setup for bootstrap installers. | Shared by installers |

## Flake Targets

| Target | Architecture | Target Medium / Purpose |
| :--- | :--- | :--- |
| `torii-chan-hdd` | `aarch64-linux` | Production SBC deployment (Root on USB SATA HDD) |
| `torii-chan-sd` | `aarch64-linux` | Production SBC deployment (Root on MicroSD) |
| `torii-chan-sd-installer` | `aarch64-linux` | Minimal SD installer image (nixosConfiguration) |
| `torii-chan-gcp` | `x86_64-linux` | Google Cloud on-demand failover node (e2-micro in asia-northeast1) |

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

- Hardware architecture, U-Boot, and storage: [docs/hardware/orange-pi-zero3.md](../../docs/hardware/orange-pi-zero3.md)
- GCP failover & recovery runbook: [docs/operations/gcp-failover.md](../../docs/operations/gcp-failover.md)
- Network topology: [docs/architecture/network-topology.md](../../docs/architecture/network-topology.md)
- Host addition runbook: [docs/operations/adding-a-host.md](../../docs/operations/adding-a-host.md)
