{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.backup;
in
{
  options.my.backup = {
    enable = mkEnableOption "restic backup configuration";
    
    paths = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of paths to backup";
    };

    exclude = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of patterns to exclude";
    };

    passwordFile = mkOption {
      type = types.str;
      description = "Path to the file containing the restic repository password";
    };

    localRepo = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Path to local repository (e.g. /mnt/tank/backups)";
    };

    remoteRepo = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "URL of remote repository (e.g. sftp:user@host:/path)";
    };

    sshKeyFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Path to SSH private key for remote backup";
    };

    timerConfig = mkOption {
      type = types.attrs;
      default = {
        OnCalendar = "00/2:00:00"; # Every 2 hours
        RandomizedDelaySec = "10m";
      };
      description = "Systemd timer configuration";
    };
  };

  config = mkIf cfg.enable {
    # Ensure restic is installed
    environment.systemPackages = [ pkgs.restic ];

    services.restic.backups = mkMerge [
      (mkIf (cfg.localRepo != null) {
        local-backup = {
          inherit (cfg) paths exclude passwordFile timerConfig;
          repository = cfg.localRepo;
          initialize = true;
          
          pruneOpts = [
            "--keep-daily 7"
            "--keep-weekly 4"
            "--keep-monthly 6"
          ];
        };
      })

      (mkIf (cfg.remoteRepo != null) {
        remote-backup = {
          inherit (cfg) paths exclude passwordFile timerConfig;
          repository = cfg.remoteRepo;
          initialize = true;
          
          extraOptions = mkIf (cfg.sshKeyFile != null) [
            "sftp.command='ssh -i ${cfg.sshKeyFile} -s sftp'"
          ];

          pruneOpts = [
            "--keep-daily 7"
            "--keep-weekly 4"
            "--keep-monthly 6"
          ];
        };
      })
    ];
  };
}
