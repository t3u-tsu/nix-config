{ config, lib, ... }:

let
  # Convert hostname hyphens to underscores and lowercase for SOPS keys
  hostKey = builtins.replaceStrings [ "-" ] [ "_" ] (lib.toLower config.networking.hostName);
in
{
  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  sops.age.sshKeyPaths = [ ];
  sops.age.generateKey = false;

  environment.variables = {
    SOPS_AGE_KEY_FILE = "/var/lib/sops-nix/key.txt";
    SOPS_AGE_SSH_PRIVATE_KEY_FILE = "/home/${config.my.user.name}/.ssh/id_ed25519";
  };

    # Common host secrets
    sops.secrets."${hostKey}_t3u_password_hash".neededForUsers = true;
    sops.secrets."${hostKey}_root_password_hash".neededForUsers = true;
  
    # GPG Private Key (shared across hosts for the primary user)
    sops.secrets.gpg_private_key = {
      path = "/run/secrets/gpg_private_key";
      owner = config.my.user.name;
      group = "users";
      mode = "0600";
    };
  }
  