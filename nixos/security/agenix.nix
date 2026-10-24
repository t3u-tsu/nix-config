{ config, ... }:
{
  age = {
    identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    rekey = {
      storageMode = "local";
      localStorageDir = ../../secrets/rekeyed + "/${config.networking.hostName}";
      masterIdentities = [
        {
          identity = "/run/user/1000/agenix/master-key.txt";
          pubkey = "age1gaalvy9u4634cu6hwnupvk35wu7pxg67xmgvl0zv66jprj4xy5xqgyw3nw";
        }
      ];
    };

    secrets = {
      t3u_password_hash.rekeyFile = ../../secrets/master/hosts/${config.networking.hostName}/t3u_password_hash.age;
      root_password_hash.rekeyFile = ../../secrets/master/hosts/${config.networking.hostName}/root_password_hash.age;
    };
  };
}
