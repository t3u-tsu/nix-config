{ config, ... }:
let
  inherit (import ../../lib/agenix.nix) masterIdentity;
in
{
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
