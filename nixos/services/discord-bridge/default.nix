{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

with lib;

let
  cfg = config.my.services.minecraft-discord-bridge;
  format = pkgs.formats.toml { };
  configFile = format.generate "bridge-config.toml" cfg.settings;

  bridgePkg = inputs.minecraft-discord-bridge.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # Read at start so the values never enter the world-readable Nix store.
  secretEnv = concatStringsSep "\n" (
    mapAttrsToList (
      name: file: "export ${name}=$(cat ${escapeShellArg file})"
    ) cfg.environmentSecretFiles
  );

  launcher = pkgs.writeShellScript "minecraft-discord-bridge-start" ''
    ${secretEnv}
    exec ${bridgePkg}/bin/minecraft-discord-bridge -c ${configFile}
  '';
in
{
  options.my.services.minecraft-discord-bridge = {
    enable = mkEnableOption "Minecraft Discord Bridge";

    settings = mkOption {
      inherit (format) type;
      default = { };
      description = "Configuration for the bridge (TOML format)";
    };

    environmentFiles = mkOption {
      type = types.listOf types.path;
      default = [ ];
      description = "Files containing environment variables (secrets)";
    };

    environmentSecretFiles = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        Environment variables whose values are read from the given files when the
        bridge starts, for secrets that are not managed by agenix.
      '';
      example = literalExpression ''
        { RCON_PASS_nitac23s = "/var/lib/minecraft/secrets/nitac23s-rcon.secret"; }
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services.minecraft-discord-bridge = {
      description = "Minecraft Discord Bridge";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = launcher;
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
