{ config, ... }:

{
  # Private flake input (github:t3u-tsu/nix-config-private): the read-only deploy
  # key lives here because root does the fetch during `sudo nixos-rebuild`, and
  # the alias keeps it off the user's other GitHub traffic.
  age.secrets.deploy_key = {
    rekeyFile = ../../secrets/master/common/deploy_key.age;
    owner = "root";
    # Readable by the users group so unprivileged users (e.g. t3u) can
    # evaluate flakes and fetch private flake inputs without root.
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
        IdentityFile ${config.age.secrets.deploy_key.path}
        IdentitiesOnly yes
    '';
  };
}
