{ nixpkgs, inputs, home-manager, disko, sops-nix }:

{
  mkSystem = { name, system, disks ? [] }:
    let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = { inherit inputs pkgs; };

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