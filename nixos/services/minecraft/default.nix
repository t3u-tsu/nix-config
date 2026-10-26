{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.services.minecraft;
  secretsDir = "/var/lib/minecraft/secrets";
in
{
  imports = [
    inputs.nix-minecraft.nixosModules.minecraft-servers
    ./proxy.nix
    ./servers
  ];

  options.my.services.minecraft = {
    enable = lib.mkEnableOption "Minecraft server services";

    forwardingSecretPath = lib.mkOption {
      type = lib.types.str;
      default = "${secretsDir}/forwarding.secret";
      description = "Velocity forwarding secret shared by the proxy and the Paper servers.";
    };

    rconSecretPath = lib.mkOption {
      type = lib.types.str;
      default = "${secretsDir}/nitac23s-rcon.secret";
      description = "RCON password used by the Discord bridge to query nitac23s.";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      inputs.nix-minecraft.overlay
    ];

    services.minecraft-servers = {
      enable = true;
      eula = true;
    };

    systemd.tmpfiles.rules = [
      "d ${secretsDir} 0750 minecraft minecraft - -"
    ];

    systemd.services = {
      # Both tokens only ever travel over loopback between services on this
      # host, so they are generated in place instead of being agenix-encrypted.
      minecraft-secrets = {
        description = "Generate local Minecraft service secrets";

        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "minecraft";
          Group = "minecraft";
        };

        script = ''
          generate() {
            if [ ! -s "$1" ]; then
              (umask 0027; ${pkgs.openssl}/bin/openssl rand -hex 32 > "$1")
            fi
          }

          generate "${cfg.forwardingSecretPath}"
          generate "${cfg.rconSecretPath}"
        '';
      };
    }
    // lib.mapAttrs' (
      name: _:
      lib.nameValuePair "minecraft-server-${name}" {
        requires = [ "minecraft-secrets.service" ];
        after = [ "minecraft-secrets.service" ];
      }
    ) config.services.minecraft-servers.servers;
  };
}
