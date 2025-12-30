{ nixpkgs, inputs, home-manager, disko, sops-nix, nix-minecraft, overlays }:

{
  mkSystem = { name, system, targetSystem ? null, disks ? [], extraModules ? [] }:
    nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = { inherit inputs; };

      modules = [
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
        nix-minecraft.nixosModules.minecraft-servers
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          nixpkgs.overlays = overlays;
        }
        (if targetSystem != null then {
          nixpkgs.crossSystem = {
            system = targetSystem;
          };
        } else {})

        ../hosts/${name}/configuration.nix
      ] ++ extraModules;
    };
}