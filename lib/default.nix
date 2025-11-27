{ nixpkgs, inputs, home-manager }:

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
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        }

        ../hosts/${name}/configuration.nix
      ];
    };
}
