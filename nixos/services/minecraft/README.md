# Minecraft Network Services (`nixos/services/minecraft/`)

Declarative multi-server Minecraft infrastructure deployed on `shosoin-tan` with automated proxy routing, Discord integration, and version-pinned plugins.

## Architecture & Server Topology

The Minecraft network deploys a lightweight Velocity/Paper reverse proxy routing inbound traffic to segregated backend servers:

| Component | Port | Inbound Hostname | Description |
| :--- | :--- | :--- | :--- |
| **Proxy** ([proxy.nix](proxy.nix)) | `25565` | `mc.t3u.uk` / `nitac23s.mc.t3u.uk` | Inbound traffic router. Public WAN requests forward through `torii-chan` over Nebula. |
| **Lobby** ([servers/lobby.nix](servers/lobby.nix)) | `25566` | `mc.t3u.uk` | Lightweight waiting lobby configured in Adventure mode on a void world (`minecraft:the_void`). |
| **Main Survival** ([servers/nitac23s.nix](servers/nitac23s.nix)) | `25567` | `nitac23s.mc.t3u.uk` | Primary survival multiplayer world. |

## External Integrations

- Integrates with [nixos/services/discord-bridge/](../discord-bridge/README.md) for dynamic player whitelist control and status metrics via a UNIX domain socket (`/run/minecraft-discord-bridge/bridge.sock`).
- Declares server plugins (protocol translation, sitting animations, Japanese chat rendering) in [nvfetcher.toml](../../../nvfetcher.toml) at the repository root, updating them automatically via GitHub Actions ([.github/workflows/auto-update.yml](../../../.github/workflows/auto-update.yml)).
- Runs Restic backups every 2 hours locally to a ZFS mirror (`/mnt/tank-1tb/backups/minecraft`) and off-site to `kagutsuchi-sama`.

## Local Secrets

The Velocity forwarding secret and the nitac23s RCON password only travel over loopback between services on `shosoin-tan`, so they are generated on first boot instead of being stored in SOPS:

| Path | Owner | Mode | Consumers |
| :--- | :--- | :--- | :--- |
| `/var/lib/minecraft/secrets/forwarding.secret` | `minecraft:minecraft` | `0640` | Velocity (`forwarding.secret`), lobby and nitac23s (`config/paper-global.yml`) |
| `/var/lib/minecraft/secrets/nitac23s-rcon.secret` | `minecraft:minecraft` | `0640` | nitac23s (`rcon.password`), Discord bridge (`RCON_PASS_nitac23s`) |

`minecraft-secrets.service` (oneshot, runs as `minecraft`) writes each file with `openssl rand -hex 32` when it is missing or empty, and every `minecraft-server-*` unit starts after it. Both locations are exposed as `my.services.minecraft.forwardingSecretPath` and `my.services.minecraft.rconSecretPath`.

Rotate a token by deleting its file and restarting the units that consume it, which regenerates it and rewrites the consuming configuration:

```bash
# Rotate the RCON password
sudo rm /var/lib/minecraft/secrets/nitac23s-rcon.secret
sudo systemctl restart minecraft-secrets.service minecraft-server-nitac23s.service minecraft-discord-bridge.service

# Rotate the forwarding secret
sudo rm /var/lib/minecraft/secrets/forwarding.secret
sudo systemctl restart minecraft-secrets.service minecraft-server-velocity.service minecraft-server-lobby.service minecraft-server-nitac23s.service
```

Credentials for external services (Discord bot tokens) remain in [secrets/services/minecraft.yaml](../../../secrets/services/minecraft.yaml) and are decrypted by SOPS.

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

- Discord Bridge module: [nixos/services/discord-bridge/](../discord-bridge/README.md)
- Backup configuration & runbook: [nixos/services/backup/](../backup/README.md) and [docs/operations/backup-and-restore.md](../../../docs/operations/backup-and-restore.md)
- Host specifications: [hosts/shosoin-tan/](../../../hosts/shosoin-tan/README.md)
- Gateway forwarding: [nixos/services/gateway/](../gateway/README.md)
