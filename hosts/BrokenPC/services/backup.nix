{ config, ... }:

{
  sops.secrets.restic_password = { };

  my.services.backup = {
    enable = true;
    paths = [
      "/home/${config.my.user.name}/Documents"
      "/home/${config.my.user.name}/Pictures"
      "/data/llama/models"
    ];
    passwordFile = config.sops.secrets.restic_password.path;
    remoteRepo = "sftp:t3u@10.0.0.4:/mnt/data/backups/BrokenPC";
    sshKeyFile = config.sops.secrets.brokenpc_ssh_private_key.path;
  };

  programs.ssh.extraConfig = ''
    Host 10.0.0.4
      StrictHostKeyChecking no
      UserKnownHostsFile /dev/null
  '';
}
