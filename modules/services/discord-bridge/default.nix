{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

with lib;

let
  cfg = config.services.minecraft-discord-bridge;
  format = pkgs.formats.toml { };
  configFile = format.generate "bridge-config.toml" cfg.settings;

  bridgePkg = inputs.minecraft-discord-bridge.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  options.services.minecraft-discord-bridge = {
    enable = mkEnableOption "Minecraft Discord Bridge";

    settings = mkOption {
      type = format.type;
      default = { };
      description = "Configuration for the bridge (TOML format)";
    };

    environmentFiles = mkOption {
      type = types.listOf types.path;
      default = [ ];
      description = "Files containing environment variables (secrets)";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.minecraft-discord-bridge = {
      description = "Minecraft Discord Bridge";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      preStart = ''
        # Ensure database directory exists and is owned by the service user
        mkdir -p /var/lib/minecraft-discord-bridge
        chown -R minecraft:minecraft /var/lib/minecraft-discord-bridge
        chmod 700 /var/lib/minecraft-discord-bridge
      '';

      serviceConfig = {
        ExecStart = "${bridgePkg}/bin/minecraft-discord-bridge -c ${configFile}";
        Restart = "always";
        RestartSec = 10;
        EnvironmentFile = cfg.environmentFiles;
        StateDirectory = "minecraft-discord-bridge";
        RuntimeDirectory = "minecraft-discord-bridge";
        User = "minecraft";
        Group = "minecraft";
      };
    };
  };
}
