# Minecraft Network Configuration

This directory manages the Minecraft network consisting of a Velocity proxy and Paper backend servers.

## Operational Status

- **Current Host**: `shosoin-tan` (10.0.1.4)
- **Data Directory**: `/srv/minecraft`
- **Backup**: Every 2 hours using `restic`.
    - Local: `/mnt/tank-1tb/backups/minecraft` (ZFS Mirror)
    - Remote: `kagutsuchi-sama` (10.0.1.3) at `/mnt/data/backups/shosoin-tan`
- **Update Producer**: `shosoin-tan` checks for core and plugin updates daily at 04:00 and updates the repository.

## Overview

- **Proxy (Velocity)**: `proxy.nix`
  - Port: `25565`
  - Domain-based routing:
    - `mc.t3u.uk` -> `lobby`
    - `nitac23s.mc.t3u.uk` -> `nitac23s`
- **Backend (Lobby)**: `servers/lobby.nix`
  - Port: `25566`
  - Waiting lobby (Void world).
- **Backend (nitac23s)**: `servers/nitac23s.nix`
  - Port: `25567`
  - Main survival server.

## Plugin Management (nvfetcher)

Plugins (ViaVersion, ViaBackwards) are managed in the `plugins/` directory using **nvfetcher**. This allows automatic fetching of latest hashes and declarative version management.

- **Automated Update**:
  If `my.autoUpdate.enable = true` is set on the host, `nvfetcher` runs automatically every day at 4 AM, and updated plugin information is pushed to the repository.
- **Manual Update**:
  ```bash
  (cd services/minecraft/plugins && nvfetcher -c nvfetcher.toml)
  ```

## Lobby Server Specifications
- **Terrain**: Void (Completely empty world with air only)
- **Biome**: `minecraft:the_void`
- **Mobs**: Natural spawning and initial placement are completely disabled (Peaceful + Spawn Limits 0).
- **Mode**: Forced Adventure mode.
- **Structures**: Disabled.

