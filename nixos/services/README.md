# System Services (`nixos/services/`)

Fleet-wide system services and background daemons managed by NixOS modules.

## Service Catalog

| Service | Scope & Purpose | Primary Host | Reference |
| :--- | :--- | :--- | :--- |
| [backup/](backup/README.md) | Multi-tier automated Restic backup system (local ZFS mirror and remote SFTP receiver). | Sender: `shosoin-tan`<br>Receiver: `kagutsuchi-sama` | [backup/](backup/README.md) |
| [desktop/](desktop/README.md) | System-level desktop services (Niri, Greetd, PipeWire, typography, Bluetooth, gaming). | Desktops (`BrokenPC`, `x1c7`) | [desktop/](desktop/README.md) |
| [discord-bridge/](discord-bridge/README.md) | Go-based Minecraft Discord bridge bot (whitelist management, status query UNIX socket). | `shosoin-tan` | [discord-bridge/](discord-bridge/README.md) |
| [emergency-ssh/](emergency-ssh/README.md) | Out-of-band SSH access via Cloudflare Tunnel for remote recovery during mesh network outages. | Servers & Gateway (`torii-chan`, `sando-kun`, `kagutsuchi-sama`, `shosoin-tan`) | [emergency-ssh/](emergency-ssh/README.md) |
| [gateway/](gateway/README.md) | Edge gateway routing, Nebula Lighthouse/Relay, Cloudflare DDNS, and Minecraft port forwarding. | `torii-chan` | [gateway/](gateway/README.md) |
| [llama.nix](llama.nix) | Local `llama.cpp` inference server (`systemd.services.llama-server`) with per-model INI presets and optional CUDA acceleration. | `BrokenPC` | [docs/hardware/hybrid-gpu.md](../../docs/hardware/hybrid-gpu.md) |
| [minecraft/](minecraft/README.md) | Minecraft Paper network (domain-routed proxy, lobby, and survival servers). | `shosoin-tan` | [minecraft/](minecraft/README.md) |
| [default.nix](default.nix) | Service module aggregator. | Fleet-wide | — |

## References

- System architecture overview: [docs/architecture/overview.md](../../docs/architecture/overview.md)
- Custom module options: [docs/architecture/flake-and-modules.md](../../docs/architecture/flake-and-modules.md)
