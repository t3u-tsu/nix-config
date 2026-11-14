# System Services (`nixos/services/`)

Fleet-wide system services and background daemons managed by NixOS modules.

## Modules

| File | Description | Options |
| :--- | :--- | :--- |
| [default.nix](default.nix) | Service module aggregator. | Imported by [nixos/default.nix](../default.nix) |
| [backup/](backup/README.md) | Multi-tier automated Restic backup system (local ZFS mirror on `shosoin-tan` and remote SFTP receiver on `kagutsuchi-sama`). | `my.services.backup.*` |
| [desktop/](desktop/README.md) | System-level desktop services (Niri, Greetd, PipeWire, typography, Bluetooth, gaming) on `BrokenPC` and `x1c7`. | `my.services.desktop.*` |
| [discord-bridge/](discord-bridge/README.md) | Go-based Minecraft Discord bridge bot (whitelist management, status query UNIX socket) on `shosoin-tan`. | `my.services.minecraft-discord-bridge.*` |
| [emergency-ssh/](emergency-ssh/README.md) | Out-of-band SSH access via Cloudflare Tunnel on `torii-chan`, `sando-kun`, `kagutsuchi-sama`, and `shosoin-tan`. | `my.services.emergency-ssh.*` |
| [gateway/](gateway/README.md) | Edge gateway routing, Nebula Lighthouse/Relay, Cloudflare DDNS, and Minecraft port forwarding on `torii-chan`. | `my.services.gateway.enable` |
| [llama/](llama/README.md) | Local `llama.cpp` inference server (`systemd.services.llama-server`) with per-model INI presets and optional CUDA acceleration on `BrokenPC`. | `my.services.llama.*` |
| [minecraft/](minecraft/README.md) | Minecraft Paper network (domain-routed proxy, lobby, and survival servers) on `shosoin-tan`. | `my.services.minecraft.*` |

## References

- System architecture overview: [docs/architecture/overview.md](../../docs/architecture/overview.md)
- Custom module options: [docs/architecture/flake-and-modules.md](../../docs/architecture/flake-and-modules.md)
