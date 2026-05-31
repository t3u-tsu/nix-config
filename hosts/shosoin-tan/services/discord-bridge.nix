{ config, pkgs, ... }:

{
  services.minecraft-discord-bridge = {
    enable = true;
    settings = {
      # Values are overridden by environment variables in sops
      discord.admin_guild_id = "SET_VIA_ENV";
      database.path = "/var/lib/minecraft-discord-bridge/bridge.db";
      bridge.socket_path = "/run/minecraft-discord-bridge/bridge.sock";
      servers.nitac23s = {
        network = "tcp";
        address = "127.0.0.1:25575";
        whitelist_path = "/srv/minecraft/nitac23s/whitelist.json";
      };
    };
    environmentFiles = [
      config.sops.secrets.discord_bridge_env.path
      config.sops.templates."discord-bridge-rcon-passwords".path
    ];
  };

  sops.secrets.discord_bridge_env = {
    sopsFile = ../../../secrets/services/minecraft.yaml;
    owner = "minecraft";
  };

  sops.templates."discord-bridge-rcon-passwords" = {
    owner = "minecraft";
    content = ''
      RCON_PASS_nitac23s=${config.sops.placeholder.nitac23s_rcon_password}
    '';
  };
}
