{ config, ... }:

{
  my.services.minecraft-discord-bridge = {
    enable = true;
    settings = {
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
    ];
    # The bridge runs as the minecraft user, which owns the secret file.
    environmentSecretFiles.RCON_PASS_nitac23s = config.my.services.minecraft.rconSecretPath;
  };

  sops.secrets.discord_bridge_env = {
    sopsFile = ../../../secrets/services/minecraft.yaml;
    owner = "minecraft";
  };

  systemd.services.minecraft-discord-bridge = {
    requires = [ "minecraft-secrets.service" ];
    after = [ "minecraft-secrets.service" ];
  };
}
