{ config, lib, ... }:

with lib;

let
  cfg = config.my.updateHub;
in {
  imports = [
    ./hub.nix
    ./client.nix
  ];

  options.my.updateHub = {
    server.enable = mkEnableOption "NixOS Update Status Hub (Server)";
    
    client = {
      enable = mkEnableOption "Automatic system and plugin updates (Client)";
      user = mkOption {
        type = types.str;
        default = config.my.user.name;
        description = "The user who owns the nix-config repository";
      };
      subdir = mkOption {
        type = types.str;
        default = "nix-config";
        description = "Subdirectory under home for the repository";
      };
      remoteUrl = mkOption {
        type = types.str;
        default = "github.com/t3u-tsu/nix-config.git";
      };
      gitUserName = mkOption {
        type = types.str;
        default = "t3u-daemon";
      };
      gitUserEmail = mkOption {
        type = types.str;
        default = "t3u+daemon@t3u.uk";
      };
      pushChanges = mkOption {
        type = types.bool;
        default = false;
        description = "Whether this host should update flake.lock and push changes to Git";
      };
      onCalendar = mkOption {
        type = types.str;
        default = "*-*-* 04:00:00";
        description = "Systemd OnCalendar expression for the update timer";
      };
      useBoot = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to use 'boot' instead of 'switch' for nixos-rebuild. Recommended for desktops.";
      };
      extraRebuildArgs = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Extra arguments to pass to nixos-rebuild switch";
      };
      hubUrl = mkOption {
        type = types.str;
        default = "http://10.0.1.1:8080";
        description = "URL of the update-hub on torii-chan";
      };
      nvfetcher = mkOption {
        type = types.listOf (types.submodule {
          options = {
            enable = mkEnableOption "Enable nvfetcher for this target";
            dir = mkOption {
              type = types.str;
              description = "Directory containing nvfetcher.toml (relative to flake root)";
            };
            configFile = mkOption {
              type = types.str;
              default = "nvfetcher.toml";
              description = "Name of the nvfetcher config file";
            };
          };
        });
        default = [];
        description = "List of nvfetcher targets to update";
      };
    };
  };

  config = mkIf cfg.server.enable {
    # Server side specific base config if any
  };
}
