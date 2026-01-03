{ config, pkgs, lib, inputs, ... }:

with lib;

let
  cfg = config.services.minecraft-discord-bridge;
  format = pkgs.formats.toml { };
  configFile = format.generate "bridge-config.toml" cfg.settings;
  
  # GitHub から取得したソースをビルド
  bridgePkg = pkgs.buildGoModule {
    pname = "minecraft-discord-bridge";
    version = "0.1.0";
    src = inputs.minecraft-discord-bridge;
    vendorHash = "sha256-W1qCmaJkLVEfBlxvIvsGhui84HOUHcKi+boC0lvozOo=";
    
    buildInputs = [ pkgs.sqlite ];
    env.CGO_ENABLED = 1;
  };
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
        ExecStart = "${bridgePkg}/bin/bridge -c ${configFile}";
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
