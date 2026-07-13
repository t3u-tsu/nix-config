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
        "https://ghostty.cachix.org?priority=30"
        "https://niri.cachix.org?priority=30"
        "https://noctalia.cachix.org?priority=30"

        "https://nix-community.cachix.org?priority=41"

        "https://cuda-maintainers.cachix.org?priority=45"
        "https://nix-gaming.cachix.org?priority=45"

        "https://chaotic-nyx.cachix.org?priority=50"
      ];

      extra-trusted-public-keys = [
        "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
      ];

      auto-optimise-store = true;
    };

    # GC every week
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  # Enable aarch64 emulation on x86_64 hosts
  boot.binfmt.emulatedSystems = lib.optional pkgs.stdenv.hostPlatform.isx86_64 "aarch64-linux";
}
