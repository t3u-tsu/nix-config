_:

{
  # Private flake input (github:t3u-tsu/nix-config-private): the read-only deploy
  # key lives here because root does the fetch during `sudo nixos-rebuild`, and
  # the alias keeps it off the user's other GitHub traffic.
  sops.secrets.nix_config_private_deploy_key = {
    sopsFile = ../../secrets/common.yaml;
    path = "/run/secrets/nix-config-private_deploy_key";
    owner = "root";
    group = "users";
    mode = "0440";
  };

  programs.ssh = {
    knownHosts."github.com".publicKey =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";

    extraConfig = ''
      Host github-nix-config-private
        HostName github.com
        User git
        IdentityFile /run/secrets/nix-config-private_deploy_key
        IdentitiesOnly yes
    '';
  };
}
