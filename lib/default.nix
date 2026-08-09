# lib/default.nix - System builder and helper functions
{
  nixpkgs,
  inputs,
  home-manager,
  sops-nix,
  nix-minecraft,
  overlays ? [ ],
}:

{
  mkSystem =
    {
      name,
      system,
      username ? "t3u",
      profile ? "tower-server",
      extraModules ? [ ],
    }:
    nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = { inherit inputs; };

      modules = [
        { my.user.name = username; }
        sops-nix.nixosModules.sops
        nix-minecraft.nixosModules.minecraft-servers
        home-manager.nixosModules.home-manager
        inputs.nix-index-database.nixosModules.nix-index
        inputs.noctalia-greeter.nixosModules.default
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            extraSpecialArgs = { inherit inputs; };
            sharedModules = [
              inputs.nix-index-database.homeModules.nix-index
              inputs.zen-browser.homeModules.default
              sops-nix.homeManagerModules.sops
              inputs.noctalia.homeModules.default
            ];
          };
          nixpkgs.overlays = overlays;
        }

        ../hosts/${name}/default.nix
      ]
      ++ extraModules;
    };
}
