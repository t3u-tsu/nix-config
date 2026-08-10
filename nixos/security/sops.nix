{
  config,
  lib,
  pkgs,
  ...
}:

let
  hostname = config.networking.hostName;
  # Convert hostname hyphens to underscores for internal SOPS key mapping
  hostKey = builtins.replaceStrings [ "-" ] [ "_" ] (lib.toLower hostname);

  hostSecretsFile = ../../secrets/hosts/${hostname}.yaml;
in
{
  sops = {
    defaultSopsFile = hostSecretsFile;
    defaultSopsFormat = "yaml";

    # Use the system's SSH host key for decryption
    # This matches the 'age' public keys derived from SSH host keys
    age = {
      keyFile = "/var/lib/sops-nix/key.txt";
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      # NOTE: keep generateKey = false. sops-nix's generateKey would create a
      # RANDOM age key (age-keygen), which cannot decrypt secrets encrypted for
      # the SSH-host-key-derived age identity. The key file is instead derived
      # from the SSH host key by the "0-sops-key-import" activation script below.
      generateKey = false;
    };

    # Secrets available on ALL hosts
    secrets."${hostKey}_t3u_password_hash".neededForUsers = true;
    secrets."${hostKey}_root_password_hash".neededForUsers = true;
  };

  # Derive the age key file from the SSH host key (the age identity registered
  # in .sops.yaml) BEFORE sops-install-secrets runs. Fixes the chicken-and-egg
  # on freshly flashed images where /var/lib/sops-nix/key.txt does not exist
  # yet but the SSH host key does (sops-install-secrets fails to read key.txt
  # even though it imports the SSH key successfully).
  # The "0-" prefix ensures textClosureMap emits this script before
  # "setupSecrets" (whose deps are specialfs/users/groups).
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
