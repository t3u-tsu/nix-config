{ config, pkgs, ... }:

{
  services.minecraft-discord-bridge = {
    enable = true;
    settings = {
      # ID is overridden by DISCORD_ADMIN_GUILD_ID env var
      discord.admin_guild_id = "@ADMIN_GUILD_ID@";
      database.path = "/var/lib/minecraft-discord-bridge/bridge.db";
      bridge.socket_path = "/run/minecraft-discord-bridge/bridge.sock";
      servers.nitac23s = {
        network = "tcp";
        address = "127.0.0.1:25575";
      };
    };
    environmentFile = config.sops.secrets.discord_bridge_env.path;
  };

  sops.secrets.discord_bridge_env = {
    owner = "minecraft";
  };
}
