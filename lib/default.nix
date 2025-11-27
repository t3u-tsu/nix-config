{ nixpkgs, inputs, home-manager, disko, sops-nix }:

{
  mkSystem = { name, system, disks ? [] }:
    nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = { inherit inputs; };

      modules = [
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        }

        ../hosts/${name}/configuration.nix
      ];
    };
}