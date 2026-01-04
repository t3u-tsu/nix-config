{ config, pkgs, lib, inputs, ... }:

with lib;

let
  cfg = config.services.minecraft-discord-bridge;
  format = pkgs.formats.toml { };
  configFile = format.generate "bridge-config.toml" cfg.settings;
  
  # Flake input からパッケージを取得
  bridgePkg = inputs.minecraft-discord-bridge.packages.${pkgs.system}.default;
in
{
  options.services.minecraft-discord-bridge = {
    enable = mkEnableOption "Minecraft Discord Bridge";
    
    settings = mkOption {
      type = format.type;
      default = { };
      description = "Configuration for the bridge (TOML format)";
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "File containing environment variables (secrets)";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.minecraft-discord-bridge = {
      description = "Minecraft Discord Bridge";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${bridgePkg}/bin/minecraft-discord-bridge -c ${configFile}";
        Restart = "always";
        EnvironmentFile = mkIf (cfg.environmentFile != null) cfg.environmentFile;
        StateDirectory = "minecraft-discord-bridge";
        WorkingDirectory = "/var/lib/minecraft-discord-bridge";
        User = "minecraft"; # マイクラのソケットにアクセスできるよう minecraft ユーザーで実行
        Group = "minecraft";
      };
    };
  };
}
