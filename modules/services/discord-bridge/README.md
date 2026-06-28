# Minecraft Discord Bridge Service

This directory manages the NixOS module for the Go-based [minecraft-discord-bridge](https://github.com/t3u-tsu/minecraft-discord-bridge).

## Overview

- **`default.nix`**: 
  - Fetches and builds the source directly from GitHub.
  - Injects secrets via `sops-nix` using environment variables.
  - Configures the Unix domain socket and Systemd service.

## Configuration

Enable the service in your host configuration (e.g., `shosoin-tan`):

```nix
services.minecraft-discord-bridge = {
  enable = true;
  settings = {
    discord.admin_guild_id = "1457...";
    database.path = "/var/lib/minecraft-discord-bridge/bridge.db";
    bridge.socket_path = "/run/minecraft-discord-bridge/bridge.sock";
    servers.nitac23s = {
      network = "tcp";
      address = "127.0.0.1:25575";
      whitelist_path = "/srv/minecraft/nitac23s/whitelist.json";
    };
  };
  environmentFiles = [ config.sops.secrets.discord_bridge_env.path ];
};
```

## Operational Commands (Local)

To control the bridge from the command line (note: it uses a Unix socket, not tmux):
```bash
echo 'status' | sudo nc -U -N /run/minecraft-discord-bridge/bridge.sock
```

## Security
- **Secret Injection**: RCON passwords and Bot tokens are securely passed through an `environmentFile`. RCON passwords for specific servers are dynamically injected using `sops.templates`.
- **Permissions**: The service runs as the `minecraft` user with minimal privileges.
