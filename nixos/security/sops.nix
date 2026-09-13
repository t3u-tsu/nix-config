{
  config,
  lib,
  pkgs,
  ...
}:

let
  hostname = config.networking.hostName;
  hostKey = config.my.hostKey;

  hostSecretsFile = ../../secrets/hosts/${hostname}.yaml;
in
{
  sops = {
    defaultSopsFile = hostSecretsFile;
    defaultSopsFormat = "yaml";

    # .sops.yaml registers the age keys derived from the SSH host key, so that
    # key is this host's decryption identity.
    age = {
      keyFile = "/var/lib/sops-nix/key.txt";
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      # Keep generateKey = false: sops-nix would otherwise create a random age
      # key that cannot decrypt secrets encrypted for the SSH-derived identity.
      # "0-sops-key-import" below derives the key file instead.
      generateKey = false;
    };

    secrets."${hostKey}_t3u_password_hash".neededForUsers = true;
    secrets."${hostKey}_root_password_hash".neededForUsers = true;
  };

  # Derive the key file from the SSH host key before sops-install-secrets runs:
  # on a freshly flashed image key.txt does not exist yet and the install fails
  # even though importing the SSH key succeeded. The "0-" prefix orders it first.
  system.activationScripts."0-sops-key-import" = lib.mkIf (config.sops.age.sshKeyPaths != [ ]) {
    deps = [ "specialfs" ];
    text = ''
      keyFile=${lib.escapeShellArg config.sops.age.keyFile}
      sshKey=${lib.escapeShellArg (toString (builtins.head config.sops.age.sshKeyPaths))}
      if [[ ! -f "$keyFile" ]] && [[ -f "$sshKey" ]]; then
        echo "sops-nix: deriving age key from SSH host key ($sshKey)..."
        mkdir -p "$(dirname "$keyFile")"
        ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i "$sshKey" > "$keyFile"
        chmod 600 "$keyFile"
      fi
    '';
  };
}
