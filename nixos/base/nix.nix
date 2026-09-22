{
  config,
  pkgs,
  lib,
  ...
}:

{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "@wheel"
        config.my.user.name
      ];

      extra-substituters = [
        # Ghostty / niri / Noctalia publish their own caches; their flake inputs
        # declare them and the hashes only match without a nixpkgs follows.
        "https://ghostty.cachix.org?priority=30"
        "https://niri.cachix.org?priority=30"
        "https://noctalia.cachix.org?priority=30"

        # General community cache.
        "https://nix-community.cachix.org?priority=41"

        # aagl launcher cache.
        "https://ezkea.cachix.org?priority=45"

        # Chaotic-Nyx patches packages that can conflict with others, so it last.
        "https://nyx-cache.chaotic.cx/?priority=50"
      ];

      extra-trusted-public-keys = [
        "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "ezkea.cachix.org-1:ioBmUbJTZIKsHmWWXPe1FSFbeVe+afhfgqgTSNd34eI="
        "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
      ];

      auto-optimise-store = true;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

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

  boot.binfmt.emulatedSystems = lib.optional pkgs.stdenv.hostPlatform.isx86_64 "aarch64-linux";
}
