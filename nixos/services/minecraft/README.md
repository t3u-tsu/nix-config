# Minecraft Network Services (`nixos/services/minecraft/`)

Declarative multi-server Minecraft infrastructure deployed on `shosoin-tan` with automated proxy routing, Discord integration, and version-pinned plugins.

## Architecture & Server Topology

The Minecraft network deploys a lightweight Velocity/Paper reverse proxy routing inbound traffic to segregated backend servers:

| Component | Port | Inbound Hostname | Description |
| :--- | :--- | :--- | :--- |
| **Proxy** ([`proxy.nix`](proxy.nix)) | `25565` | `mc.t3u.uk` / `nitac23s.mc.t3u.uk` | Inbound traffic router. Public WAN requests forward through `torii-chan` over Nebula. |
| **Lobby** ([`servers/lobby.nix`](servers/lobby.nix)) | `25566` | `mc.t3u.uk` | Lightweight waiting lobby configured in Adventure mode on a void world (`minecraft:the_void`). |
| **Main Survival** ([`servers/nitac23s.nix`](servers/nitac23s.nix)) | `25567` | `nitac23s.mc.t3u.uk` | Primary survival multiplayer world. |

## External Integrations

- **Discord Bridge:** Integrated via [`nixos/services/discord-bridge/`](../discord-bridge/README.md) for dynamic player whitelist control and status metrics via UNIX domain socket (`/run/minecraft-discord-bridge/bridge.sock`).
- **Plugin Management:** Server plugins (protocol translation, sitting animations, Japanese chat rendering) are declared in [`nvfetcher.toml`](../../../nvfetcher.toml) at the repository root and updated automatically via GitHub Actions ([`.github/workflows/auto-update.yml`](../../../.github/workflows/auto-update.yml)).
- **Backup Schedule:** Backed up every 2 hours locally to ZFS Mirror (`/mnt/tank-1tb/backups/minecraft`) and off-site to `kagutsuchi-sama` via Restic.

## CLI Operations (on `shosoin-tan`)

```bash
# Check Discord bridge status
echo 'status' | sudo nc -U -N /run/minecraft-discord-bridge/bridge.sock

# Create a guild invitation token
echo 'invite-create nitac23s' | sudo nc -U -N /run/minecraft-discord-bridge/bridge.sock

# Trigger manual plugin updates via nvfetcher
nix run nixpkgs#nvfetcher
```

## References

- Discord Bridge module: [`nixos/services/discord-bridge/`](../discord-bridge/README.md)
- Backup configuration & runbook: [`nixos/services/backup/`](../backup/README.md) and [`docs/operations/backup-and-restore.md`](../../../docs/operations/backup-and-restore.md)
- Host specifications: [`hosts/shosoin-tan/`](../../../hosts/shosoin-tan/README.md)
- Gateway forwarding: [`nixos/services/gateway/`](../gateway/README.md)
