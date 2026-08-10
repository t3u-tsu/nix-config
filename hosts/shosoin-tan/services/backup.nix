{ config, pkgs, ... }:

{
  sops.secrets.restic_password = {
    sopsFile = ../../../secrets/services/backup.yaml;
  };
  sops.secrets.restic_shosoin_ssh_key = {
    sopsFile = ../../../secrets/services/backup.yaml;
  };

  my.services.backup = {
    enable = true;
    paths = [
      "/srv/minecraft"
      "/var/lib/minecraft-discord-bridge"
    ];
    passwordFile = config.sops.secrets.restic_password.path;
    localRepo = "/mnt/tank-1tb/backups/minecraft";
    remoteRepo = "sftp:restic-shosoin@10.0.0.3:/mnt/data/backups/shosoin-tan";
    sshKeyFile = config.sops.secrets.restic_shosoin_ssh_key.path;

    backupPrepareCommand = ''
      # Disable auto-save and flush to disk for all servers
      for server in lobby nitac23s; do
        if [ -S /run/minecraft/$server.sock ]; then
          ${pkgs.tmux}/bin/tmux -S /run/minecraft/$server.sock send-keys "save-off" ENTER
          ${pkgs.tmux}/bin/tmux -S /run/minecraft/$server.sock send-keys "save-all flush" ENTER
        fi
      done
      sleep 2
    '';

    backupCleanupCommand = ''
      # Re-enable auto-save
      for server in lobby nitac23s; do
        if [ -S /run/minecraft/$server.sock ]; then
          ${pkgs.tmux}/bin/tmux -S /run/minecraft/$server.sock send-keys "save-on" ENTER
        fi
      done
    '';
  };

  # SSH configuration for restic backup (kagutsuchi-sama over nebula0).
  programs.ssh.extraConfig = ''
    Host 10.0.0.3
      IdentityFile ${config.sops.secrets.restic_shosoin_ssh_key.path}
      StrictHostKeyChecking no
      UserKnownHostsFile /dev/null
  '';
}
