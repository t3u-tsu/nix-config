{
  nixpkgs,
  inputs,
  home-manager,
  sops-nix,
  agenix,
  agenix-rekey,
  overlays ? [ ],
}:

{
  # Builds a nixosConfiguration from a role profile plus ../hosts/<name>/default.nix;
  # extraModules are appended last so callers can override what the profile set.
  # Arguments and the returned system are documented in lib/README.md.
  mkSystem =
    {
      name,
      system,
      username ? "t3u",
      profile,
      extraModules ? [ ],
    }:
    nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = { inherit inputs; };

      modules = [
        { my.user.name = username; }
        sops-nix.nixosModules.sops
        agenix.nixosModules.default
        agenix-rekey.nixosModules.default
        home-manager.nixosModules.home-manager
        inputs.nix-index-database.nixosModules.nix-index
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            extraSpecialArgs = { inherit inputs; };
            sharedModules = [
              inputs.nix-index-database.homeModules.nix-index
              sops-nix.homeManagerModules.sops
              agenix.homeManagerModules.default
              agenix-rekey.homeManagerModules.default
            ];
          };
          nixpkgs.overlays = overlays;
        }

        ../nixos
        ../nixos/profiles/${profile}
        ../hosts/${name}/default.nix
      ]
      ++ extraModules;
    };
}
