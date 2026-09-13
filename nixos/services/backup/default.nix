{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.my.services.backup;

  # "sftp:user@host:/path" -> "host"; null when the URL has no user@host part.
  repoHost =
    repo:
    let
      m = builtins.match ".*@([^:]+):.*" repo;
    in
    if m == null then null else builtins.head m;

  sshHost = if cfg.remoteRepo == null then null else repoHost cfg.remoteRepo;

  sshIdentity = optionalString (cfg.sshKeyFile != null && sshHost != null) ''
    Host ${sshHost}
      IdentityFile ${cfg.sshKeyFile}
  '';

  mkBackup = name: repo: {
    ${name} = {
      inherit (cfg)
        paths
        exclude
        passwordFile
        timerConfig
        backupPrepareCommand
        backupCleanupCommand
        ;
      repository = repo;
      initialize = true;

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
      ];
    };
  };
in
{
  options.my.services.backup = {
    enable = mkEnableOption "restic backup configuration";

    paths = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of paths to backup";
    };

    exclude = mkOption {
      type = types.listOf types.str;
      default = [ ];
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
      description = "SSH private key added as an IdentityFile for the remote repository's host.";
    };

    backupPrepareCommand = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Command to run before backup starts";
    };

    backupCleanupCommand = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Command to run after backup finishes";
    };

    timerConfig = mkOption {
      type = types.attrs;
      default = {
        OnCalendar = "00/2:00:00";
        RandomizedDelaySec = "10m";
      };
      description = "Systemd timer configuration";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.restic ];

    # restic has no ssh-key option: its SFTP backend shells out to the system ssh
    # client, so the identity has to arrive through ssh_config.
    programs.ssh.extraConfig = sshIdentity;

    services.restic.backups = mkMerge [
      (mkIf (cfg.localRepo != null) (mkBackup "local-backup" cfg.localRepo))
      (mkIf (cfg.remoteRepo != null) (mkBackup "remote-backup" cfg.remoteRepo))
    ];
  };
}
