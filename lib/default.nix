{ nixpkgs, inputs, home-manager, disko, sops-nix }:

{
  mkSystem = { name, system, disks ? [] }:
    nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };

      modules = [
        {
          nixpkgs.buildPlatform.system = "x86_64-linux";
          nixpkgs.hostPlatform.system = system;
          nixpkgs.config.allowUnfree = true;
        }
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