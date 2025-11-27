{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, disko, sops-nix, ... }@inputs:
    let
      lib = import ./lib {
        inherit nixpkgs inputs home-manager disko sops-nix;
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
