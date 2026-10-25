{ config, osConfig, ... }:
let
  inherit (import ../lib/agenix.nix) masterIdentity;
in
{
  age = {
    identityPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];

    rekey = {
      storageMode = "local";
      localStorageDir = ../secrets/rekeyed/home/${osConfig.networking.hostName}/${config.home.username};
      masterIdentities = [ masterIdentity ];
    };
  };
}
