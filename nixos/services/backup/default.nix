{
  config,
  lib,
  pkgs,
  ...
}:

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

  sshIdentity =
    if cfg.sshKeyFile == null || cfg.remoteRepo == null then
      ""
    else if sshHost != null then
      ''
        Host ${sshHost}
          IdentityFile ${cfg.sshKeyFile}
      ''
    else
      lib.warn "my.services.backup: sshKeyFile is set but remoteRepo '${cfg.remoteRepo}' has no user@host, so no IdentityFile is emitted" "";

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
  imports = [ ./receiver.nix ];

  options.my.services.backup = {
    enable = lib.mkEnableOption "restic backup configuration";

    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of paths to backup";
    };

    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of patterns to exclude";
    };

    passwordFile = lib.mkOption {
      type = lib.types.str;
      description = "Path to the file containing the restic repository password";
    };

    localRepo = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to local repository (e.g. /mnt/tank/backups)";
    };

    remoteRepo = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "URL of remote repository (e.g. sftp:user@host:/path)";
    };

    sshKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "SSH private key added as an IdentityFile for the remote repository's host.";
    };

    backupPrepareCommand = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Command to run before backup starts";
    };

    backupCleanupCommand = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Command to run after backup finishes";
    };

    timerConfig = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {
        OnCalendar = "00/2:00:00";
        RandomizedDelaySec = "10m";
      };
      description = "Systemd timer configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.restic ];

    # restic has no ssh-key option: its SFTP backend shells out to the system ssh
    # client, so the identity has to arrive through ssh_config.
    programs.ssh.extraConfig = sshIdentity;

    services.restic.backups = lib.mkMerge [
      (lib.mkIf (cfg.localRepo != null) (mkBackup "local-backup" cfg.localRepo))
      (lib.mkIf (cfg.remoteRepo != null) (mkBackup "remote-backup" cfg.remoteRepo))
    ];
  };
}
