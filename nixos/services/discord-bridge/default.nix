{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  cfg = config.my.services.minecraft-discord-bridge;
  format = pkgs.formats.toml { };
  configFile = format.generate "bridge-config.toml" cfg.settings;

  bridgePkg = inputs.minecraft-discord-bridge.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # Read at start so the values never enter the world-readable Nix store.
  secretEnv = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      name: file: "export ${name}=\"$(cat ${lib.escapeShellArg file})\""
    ) cfg.environmentSecretFiles
  );

  launcher = pkgs.writeShellScript "minecraft-discord-bridge-start" ''
    ${secretEnv}
    exec ${lib.escapeShellArg "${bridgePkg}/bin/minecraft-discord-bridge"} -c ${lib.escapeShellArg configFile}
  '';
in
{
  options.my.services.minecraft-discord-bridge = {
    enable = lib.mkEnableOption "Minecraft Discord Bridge";

    settings = lib.mkOption {
      inherit (format) type;
      default = { };
      description = "Configuration for the bridge (TOML format)";
    };

    environmentFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "Files containing environment variables (secrets)";
    };

    environmentSecretFiles = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = ''
        Environment variables whose values are read from the given files when the
        bridge starts, for secrets that are not already in systemd EnvironmentFile format.
      '';
      example = lib.literalExpression ''
        { RCON_PASS_nitac23s = "/var/lib/minecraft/secrets/nitac23s-rcon.secret"; }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
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
