{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.my.nix.distributedBuilds;
in
{
  options.my.nix.distributedBuilds.enable = lib.mkEnableOption "offloading builds to BrokenPC";

  config = {
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
          "https://niri.cachix.org?priority=30"
          "https://noctalia.cachix.org?priority=30"

          # General community cache.
          "https://nix-community.cachix.org?priority=41"
          "https://cache.numtide.com?priority=42"

          # aagl launcher cache.
          "https://ezkea.cachix.org?priority=45"
        ];

        extra-trusted-public-keys = [
          "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
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

      distributedBuilds = lib.mkIf cfg.enable true;

      buildMachines = lib.mkIf cfg.enable [
        {
          hostName = "10.0.0.100";
          system = "x86_64-linux";
          maxJobs = 8;
          supportedFeatures = [
            "nixos-test"
            "benchmark"
            "big-parallel"
            "kvm"
          ];
        }
      ];
    };

    boot.binfmt.emulatedSystems = lib.optional pkgs.stdenv.hostPlatform.isx86_64 "aarch64-linux";
  };
}
