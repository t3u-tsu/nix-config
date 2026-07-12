{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.my.services.minecraft;
  serverMapping = {
    "mc.t3u.uk" = "lobby";
    "nitac23s.mc.t3u.uk" = "nitac23s";
  };
in
{
  config = mkIf cfg.enable {
    services.minecraft-servers.servers.velocity = {
      enable = true;
      package = pkgs.velocity-server;

      jvmOpts = "-Xms512M -Xmx512M";

      files = {
        "velocity.toml".value = {
          config-version = "2.7";
          bind = "0.0.0.0:25565";
          motd = "Minecraft server network hosted by t3u";
          show-max-players = 3939;
          online-mode = true;
          force-key-authentication = true;
          player-info-forwarding-mode = "modern";

          servers = {
            lobby = "127.0.0.1:25566";
            nitac23s = "127.0.0.1:25567";
          };

          forced-hosts = lib.mapAttrs (_: v: [ v ]) serverMapping;

          try = [ "lobby" ];
        };
      };

      symlinks = {
        "forwarding.secret" = config.sops.secrets.minecraft_forwarding_secret.path;
      };
    };
  };
}
