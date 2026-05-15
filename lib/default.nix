{ nixpkgs, inputs, home-manager, disko, sops-nix, nix-minecraft, overlays }:

{
  mkSystem = { name, system, username ? "t3u", targetSystem ? null, disks ? [], extraModules ? [] }:
    nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = { inherit inputs; };

      modules = [
        { my.user.name = username; }
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
        nix-minecraft.nixosModules.minecraft-servers
        home-manager.nixosModules.home-manager
        inputs.nix-index-database.nixosModules.nix-index
        inputs.comin.nixosModules.comin
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.sharedModules = [
            inputs.nix-index-database.homeModules.nix-index
            inputs.zen-browser.homeModules.default
            sops-nix.homeManagerModules.sops
          ];
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

  # Auto-update helpers
  autoUpdate = {
    mkNvfetcherTask = dir: {
      enable = true;
      inherit dir;
    };
  };
}