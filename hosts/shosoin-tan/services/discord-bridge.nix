{ config, pkgs, ... }:

{
  services.minecraft-discord-bridge = {
    enable = true;
    settings = {
      # ID is overridden by DISCORD_ADMIN_GUILD_ID env var
      discord.admin_guild_id = "@ADMIN_GUILD_ID@";
      database.path = "/var/lib/minecraft-discord-bridge/bridge.db";
...
  sops.secrets.discord_bridge_env = {
    owner = "minecraft";
  };
}
