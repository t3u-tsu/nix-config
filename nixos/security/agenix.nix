{ config, ... }:
let
  inherit (import ../../lib/agenix.nix) masterIdentity;
in
{
  # Dedicated noswap tmpfs for the operator's master identity. The scripts
  # create master-key.txt here with mode 0400 and remove it on exit.
  fileSystems."/run/agenix-master" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "mode=0700"
      "nosuid"
      "nodev"
      "noexec"
      "noswap"
      "size=1M"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /run/agenix-master 0700 ${config.my.user.name} ${
      config.users.users.${config.my.user.name}.group
    } - -"
  ];

  age = {
    identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    rekey = {
      storageMode = "local";
      localStorageDir = ../../secrets/rekeyed/hosts/${config.networking.hostName};
      masterIdentities = [ masterIdentity ];
    };

    secrets = {
      user_password_hash = {
        rekeyFile = ../../secrets/master/hosts/${config.networking.hostName}/user_password_hash.age;
      };
      root_password_hash = {
        rekeyFile = ../../secrets/master/hosts/${config.networking.hostName}/root_password_hash.age;
      };
    };
  };
}
