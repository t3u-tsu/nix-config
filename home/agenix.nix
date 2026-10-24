{ config, ... }:
{
  age = {
    identityPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];

    rekey = {
      storageMode = "local";
      localStorageDir = ../../secrets/rekeyed/home + "/${config.home.username}";
      masterIdentities = [
        {
          identity = "/run/user/1000/agenix/master-key.txt";
          pubkey = "age1gaalvy9u4634cu6hwnupvk35wu7pxg67xmgvl0zv66jprj4xy5xqgyw3nw";
        }
      ];
    };
  };
}
