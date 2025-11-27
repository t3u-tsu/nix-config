{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      lib = import ./lib {
        inherit nixpkgs inputs home-manager;
      };
    in
    {
      nixosConfigurations = {
        "torii-chan" = lib.mkSystem {
          name = "torii-chan";
          system = "aarch64-linux";
        };
      };
    };
}
