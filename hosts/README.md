# Hosts (`hosts/`)

Machine configurations for physical and virtual hosts in the fleet. Each host is registered in `flake/hosts.nix` using `mkLib.mkSystem` and configured through its `default.nix` entrypoint.

## Fleet Overview

| Host | Profile | Architecture | Nebula IP | Hardware Model | Primary Roles |
| :--- | :--- | :--- | :--- | :--- | :--- |
| [`BrokenPC`](BrokenPC/README.md) | `desktop` | `x86_64-linux` | `10.0.0.100` | HP Victus 16-e1065AX | Secondary portable laptop (Site A / mobile), local LLM inference |
| [`x1c7`](x1c7/README.md) | `desktop` | `x86_64-linux` | `10.0.0.101` | ThinkPad X1 Carbon Gen 7 | Mobile laptop, low-latency UI |
| [`shosoin-tan`](shosoin-tan/README.md) | `tower-server` | `x86_64-linux` | `10.0.0.4` | Core i7-870 Tower | Minecraft server, Discord Bridge, ZFS Mirror storage |
| [`kagutsuchi-sama`](kagutsuchi-sama/README.md) | `tower-server` | `x86_64-linux` | `10.0.0.3` | Xeon E5-2650 v2 Tower | Compute server, Restic backup receiver |
| [`sando-kun`](sando-kun/README.md) | `tower-server` | `x86_64-linux` | `10.0.0.2` | Core i7-860 Tower | General-purpose tower server (Legacy BIOS) |
| [`torii-chan`](torii-chan/README.md) | `gateway` / `sbc` | `aarch64-linux` | `10.0.0.1` | Orange Pi Zero 3 | Primary Nebula Lighthouse & Relay, NAT gateway |
| `torii-chan-vps` | `gateway` | `x86_64-linux` | `10.0.0.1` (standby) | ConoHa VPS (512MB) | Failover Lighthouse & Relay (takes over 10.0.0.1 on SBC outage) |

## Directory Layout

Each host directory follows a uniform structure:

```text
hosts/<hostname>/
├── default.nix     # Primary entrypoint (imports hardware.nix and services/)
├── hardware.nix    # Storage partitions, swap, and kernel parameters
├── services/       # Host-specific service definitions
│   ├── default.nix # Service imports
│   └── nebula.nix  # Nebula mesh assignment (IP, groups)
└── README.md       # Hardware specs, quick rebuild commands, and operational notes
```

## Adding a Host

1. Copy the skeleton: `cp -r hosts/_template hosts/<hostname>`
2. Follow the step-by-step runbook in [`docs/operations/adding-a-host.md`](../docs/operations/adding-a-host.md) (covers SOPS age keys, Nebula certificates, private input bootstrap, and verification).

## References

- Host addition runbook: [`docs/operations/adding-a-host.md`](../docs/operations/adding-a-host.md)
- Network topology & IP allocation: [`docs/architecture/network-topology.md`](../docs/architecture/network-topology.md)
- System evaluation architecture: [`docs/architecture/overview.md`](../docs/architecture/overview.md)
