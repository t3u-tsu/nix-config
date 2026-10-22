# Minecraft Discord Bridge (`nixos/services/discord-bridge/`)

NixOS service module integrating the Go-based [minecraft-discord-bridge](https://github.com/t3u-tsu/minecraft-discord-bridge) for automated Discord-Minecraft player whitelist management.

## Module Architecture

- **Build Pipeline:** Compiles the bridge binary directly from the upstream GitHub repository.
- **IPC Interface:** Exposes a local UNIX domain socket at `/run/minecraft-discord-bridge/bridge.sock` for operator queries.
- **Privilege Separation:** Operates under dedicated unprivileged `minecraft` user and group.
- **Secret Delivery:** Injects Discord bot tokens and server RCON passwords via SOPS-templated environment files.

## Configuration Example

```nix
my.services.minecraft-discord-bridge = {
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

## CLI Operations

Communicate with the running daemon over its UNIX domain socket using `nc`:

```bash
# Query daemon status
echo 'status' | sudo nc -U -N /run/minecraft-discord-bridge/bridge.sock

# Generate an invitation token for a guild
echo 'invite-create nitac23s' | sudo nc -U -N /run/minecraft-discord-bridge/bridge.sock
```

## References

- Minecraft network configuration: [`nixos/services/minecraft/`](../minecraft/README.md)
- Host deployment: [`hosts/shosoin-tan/`](../../../hosts/shosoin-tan/README.md)
