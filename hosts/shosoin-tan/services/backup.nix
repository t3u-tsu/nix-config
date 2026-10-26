{ config, pkgs, ... }:

{
  age.secrets.restic_password = {
    rekeyFile = ../../../secrets/master/services/backup/password.age;
  };
  age.secrets.restic_ssh_key = {
    rekeyFile = ../../../secrets/master/services/backup/ssh_key.age;
  };

  my.services.backup = {
    enable = true;
    paths = [
      "/srv/minecraft"
      "/var/lib/minecraft-discord-bridge"
    ];
    passwordFile = config.age.secrets.restic_password.path;
    localRepo = "/mnt/tank-1tb/backups/minecraft";
    remoteRepo = "sftp:restic-shosoin@10.0.0.3:/mnt/data/backups/shosoin-tan";
    sshKeyFile = config.age.secrets.restic_ssh_key.path;

    backupPrepareCommand = ''
      for server in lobby nitac23s; do
        if [ -S /run/minecraft/$server.sock ]; then
          ${pkgs.tmux}/bin/tmux -S /run/minecraft/$server.sock send-keys "save-off" ENTER
          ${pkgs.tmux}/bin/tmux -S /run/minecraft/$server.sock send-keys "save-all flush" ENTER
        fi
      done
      sleep 2
    '';

    backupCleanupCommand = ''
      for server in lobby nitac23s; do
        if [ -S /run/minecraft/$server.sock ]; then
          ${pkgs.tmux}/bin/tmux -S /run/minecraft/$server.sock send-keys "save-on" ENTER
        fi
      done
    '';
  };

  # SSH configuration for restic backup (kagutsuchi-sama over nebula0).
  # restic's SSH identity comes from my.services.backup.sshKeyFile.
  programs.ssh.knownHosts."10.0.0.3".publicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJVL9zWhWDBJNs7J14zAD+FHK5sHOcaFSP8p8EFaY1CI";
}
