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
        "https://noctalia.cachix.org?priority=30"
        "https://nix-community.cachix.org?priority=41"
        "https://cache.numtide.com?priority=42"
        "https://ezkea.cachix.org?priority=45"
      ];

      extra-trusted-public-keys = [
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "ezkea.cachix.org-1:ioBmUbJTZIKsHmWWXPe1FSFbeVe+afhfgqgTSNd34eI="
      ];

      auto-optimise-store = true;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  boot.binfmt.emulatedSystems = lib.optional pkgs.stdenv.hostPlatform.isx86_64 "aarch64-linux";
}
