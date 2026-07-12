{ config, lib, ... }:

let
  hostname = config.networking.hostName;
  # Convert hostname hyphens to underscores for internal SOPS key mapping
  hostKey = builtins.replaceStrings [ "-" ] [ "_" ] (lib.toLower hostname);

  # Path to the host-specific secrets file
  hostSecretsFile = ../../secrets/hosts/${hostname}.yaml;
in
{
  sops.defaultSopsFile = hostSecretsFile;
  sops.defaultSopsFormat = "yaml";

  # Use the system's SSH host key for decryption
  # This matches the 'age' public keys derived from SSH host keys
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.age.generateKey = false;

  # Secrets available on ALL hosts
  sops.secrets."${hostKey}_t3u_password_hash".neededForUsers = true;
  sops.secrets."${hostKey}_root_password_hash".neededForUsers = true;

  # Example of how to include common/service secrets in other modules:
  # sops.secrets.some_shared_key = {
  #   sopsFile = ../../secrets/common.yaml;
  # };
}
