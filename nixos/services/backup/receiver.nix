{ config, lib, ... }:

{
  options.my.services.backup.receiver.enable = lib.mkEnableOption "restic backup receiver";

  config = lib.mkIf config.my.services.backup.receiver.enable {
    users.groups.restic-shosoin = { };

    users.users.restic-shosoin = {
      isNormalUser = true;
      group = "restic-shosoin";
      home = "/mnt/data/backups/shosoin-tan";
      createHome = true;
      openssh.authorizedKeys.keys = [
        # Restrict to SFTP only
        "command=\"internal-sftp\",restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIdEMmGQ8A3+7Qlhd3uA6vUJVLWwY+XqZyCRVe9hUiZi t3u@BrokenPC"
      ];
    };
  };
}
