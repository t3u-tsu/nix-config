{ config, lib, ... }:

let
  cfg = config.my.services.backup.receiver;
in
{
  options.my.services.backup.receiver = {
    enable = lib.mkEnableOption "restic backup receiver";

    user = lib.mkOption {
      type = lib.types.str;
      default = "restic-shosoin";
      description = "Unix user owning the received restic repository.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "restic-shosoin";
      description = "Unix group owning the received restic repository.";
    };

    home = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/data/backups/shosoin-tan";
      description = "Home directory (repository root) of the receiver user.";
    };

    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "command=\"internal-sftp\",restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIdEMmGQ8A3+7Qlhd3uA6vUJVLWwY+XqZyCRVe9hUiZi"
      ];
      description = "SSH public keys allowed to upload backups (forced to internal-sftp).";
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.${cfg.group} = { };

    users.users.${cfg.user} = {
      isNormalUser = true;
      createHome = true;
      inherit (cfg) group home;
      openssh.authorizedKeys.keys = cfg.authorizedKeys;
    };
  };
}
