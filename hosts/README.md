# hosts/ — Host Directory & Fleet Overview

This directory contains machine-specific definitions for all physical and virtual hosts in the fleet. Each host is registered in `flake/hosts.nix` via `mkLib.mkSystem` and provides a `default.nix` entrypoint.

## Fleet Overview

| Host | Profile | Architecture | Nebula IP | Hardware Model | Primary Roles |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **[`BrokenPC`](BrokenPC/)** | `desktop` | `x86_64-linux` | `10.0.0.100` | HP Victus 16-e1065AX | Secondary portable laptop (Base A / mobile), local LLM inference |
| **[`x1c7`](x1c7/)** | `desktop` | `x86_64-linux` | `10.0.0.101` | ThinkPad X1 Carbon Gen 7 | Mobile laptop, low-latency UI |
| **[`shosoin-tan`](shosoin-tan/)** | `tower-server` | `x86_64-linux` | `10.0.0.4` | Core i7-870 Tower | Minecraft server, Discord Bridge, ZFS Mirror |
| **[`kagutsuchi-sama`](kagutsuchi-sama/)** | `tower-server` | `x86_64-linux` | `10.0.0.3` | Xeon E5-2650 v2 Tower | Compute server, Restic backup receiver |
| **[`sando-kun`](sando-kun/)** | `tower-server` | `x86_64-linux` | `10.0.0.2` | Core i7-860 Tower | General-purpose tower server |
| **[`torii-chan`](torii-chan/)** | `gateway` / `sbc` | `aarch64-linux` | `10.0.0.1` | Orange Pi Zero 3 | Primary Nebula Lighthouse & Relay, NAT gateway |
| **`torii-chan-vps`** | `gateway` | `x86_64-linux` | `10.0.0.1` (standby) | ConoHa VPS (512MB) | Failover Lighthouse & Relay (takes over 10.0.0.1 on SBC outage) |

## Directory Structure

A standard host directory contains:

```text
hosts/<hostname>/
├── default.nix     # Primary entrypoint (imports hardware.nix, services/, and ../../nixos)
├── hardware.nix    # Storage partitions, swap, and kernel parameters
├── services/       # Host-specific service definitions
│   ├── default.nix # Service imports
│   └── nebula.nix  # Nebula mesh assignment (IP, groups)
└── README.md       # Hardware specs, quick rebuild commands, and quirks
```

## Adding a New Host

To add a new machine to the fleet:
1. Copy the skeleton: `cp -r hosts/_template hosts/<hostname>`
2. Follow the comprehensive, step-by-step runbook in [`docs/operations/adding-a-host.md`](../docs/operations/adding-a-host.md) (covers SOPS age keys, Nebula certificates, private input bootstrap, and verification).

## References
- Unified host addition runbook: [`docs/operations/adding-a-host.md`](../docs/operations/adding-a-host.md)
- Network topology & IP allocation: [`docs/architecture/network-topology.md`](../docs/architecture/network-topology.md)
- System evaluation architecture: [`docs/architecture/overview.md`](../docs/architecture/overview.md)
