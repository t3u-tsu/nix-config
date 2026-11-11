# Hosts (`hosts/`)

Machine configurations for physical and virtual hosts in the fleet. Each host is registered once in the `fleet` attrset in [flake/hosts.nix](../flake/hosts.nix) and configured through its `default.nix` entrypoint.

## Fleet Overview

| Host | Profile | Architecture | Nebula IP | Hardware Model | Primary Roles |
| :--- | :--- | :--- | :--- | :--- | :--- |
| [BrokenPC](BrokenPC/README.md) | `desktop` | `x86_64-linux` | `10.0.0.100` | HP Victus 16-e1065AX | Secondary portable laptop (Site A / mobile), local LLM inference |
| [x1c7](x1c7/README.md) | `desktop` | `x86_64-linux` | `10.0.0.101` | ThinkPad X1 Carbon Gen 7 | Mobile laptop, low-latency UI |
| [shosoin-tan](shosoin-tan/README.md) | `tower-server` | `x86_64-linux` | `10.0.0.4` | Core i7-870 Tower | Minecraft server, Discord Bridge, ZFS Mirror storage |
| [kagutsuchi-sama](kagutsuchi-sama/README.md) | `tower-server` | `x86_64-linux` | `10.0.0.3` | Xeon E5-2650 v2 Tower | Compute server, Restic backup receiver |
| [sando-kun](sando-kun/README.md) | `tower-server` | `x86_64-linux` | `10.0.0.2` | Core i7-860 Tower | General-purpose tower server (Legacy BIOS) |
| [torii-chan](torii-chan/README.md) | `gateway` | `aarch64-linux` | `10.0.0.1` | Orange Pi Zero 3 | Primary Nebula Lighthouse & Relay, NAT gateway; SBC constraints from [sbc.nix](torii-chan/sbc.nix) |
| `torii-chan-gcp` | `gateway` | `x86_64-linux` | `10.0.0.1` (standby) | Google Cloud e2-micro (asia-northeast1) | Failover Lighthouse & Relay (takes over 10.0.0.1 on SBC outage) |

`torii-chan` is declared with `variants`, so the fleet exposes it as `torii-chan-sd-installer`, `torii-chan-sd`, `torii-chan-hdd`, and `torii-chan-gcp`.

## Registration

Every host has exactly one entry in the `fleet` attrset in [flake/hosts.nix](../flake/hosts.nix). The entry carries the platform and role profile; [flake/hosts.nix](../flake/hosts.nix) expands each entry into a `nixosConfiguration` via `mkSystem` in [lib/default.nix](../lib/default.nix), which wires in `nixos/profiles/<profile>` and `hosts/<hostname>/default.nix`.

```nix
x1c7 = {
  system = "x86_64-linux";
  profile = "desktop";
};
```

Hosts running the same role on multiple boot media or platforms list them under `variants`. Each variant becomes a `<name>-<variant>` configuration; variant fields override the host-level ones, except `extraModules`, which are appended to the host-level list (`torii-chan` is the only current example).

```nix
torii-chan = {
  profile = "gateway";
  variants = {
    hdd = {
      system = "aarch64-linux";
      extraModules = [
        ../hosts/torii-chan/sbc.nix
        ../hosts/torii-chan/fs-hdd.nix
      ];
    };
    gcp = {
      system = "x86_64-linux";
      extraModules = [ ../hosts/torii-chan/gcp.nix ];
    };
  };
};
```

## Directory Layout

Most host configurations follow this layout. `torii-chan` is the exception: its `default.nix` only carries the shared role, and the boot chain, filesystems, and WAN networking come from per-platform modules (`sbc.nix` / `gcp.nix` / `fs-hdd.nix` / `fs-sd.nix`) selected in [flake/hosts.nix](../flake/hosts.nix).

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

1. Copy the skeleton using `cp -r hosts/_template hosts/<hostname>`.
2. Add the host to the `fleet` attrset in [flake/hosts.nix](../flake/hosts.nix) as `{ system = "..."; profile = "..."; }`, listing `variants` when the role runs on several boot media or platforms.
3. Follow the step-by-step runbook in [docs/operations/adding-a-host.md](../docs/operations/adding-a-host.md) (covers agenix host keys, Nebula certificates, private input bootstrap, and verification).

## References

- Host addition runbook: [docs/operations/adding-a-host.md](../docs/operations/adding-a-host.md)
- Network topology & IP allocation: [docs/architecture/network-topology.md](../docs/architecture/network-topology.md)
- System evaluation architecture: [docs/architecture/overview.md](../docs/architecture/overview.md)
- Failover gateway runbook: [docs/operations/gcp-failover.md](../docs/operations/gcp-failover.md)
