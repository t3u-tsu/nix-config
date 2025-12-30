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
      # Overlays for cross-compilation
      overlays = [
        (final: prev: {
          ubootOrangePiZero3 = prev.buildUBoot {
            version = "2024.01";
            defconfig = "orangepi_zero3_defconfig";
            extraMeta.platforms = [ "aarch64-linux" ];
            BL31 = "${prev.armTrustedFirmwareAllwinnerH616}/bl31.bin";
            filesToInstall = [ "u-boot-sunxi-with-spl.bin" ];
            src = prev.fetchFromGitHub {
              owner = "u-boot";
              repo = "u-boot";
              rev = "v2024.01"; # New version with H618 support
              sha256 = "sha256-0Da7Czy9cpQ+D5EICc3/QSZhAdCBsmeMvBgykYhAQFw="; # Placeholder hash
            };
          };
        })
      ];
    in
    {
      nixosConfigurations = {
        # 1. For SD card creation (No Disko, uses standard modules)
        "torii-chan-sd" = lib.mkSystem {
          name = "torii-chan"; # Same hostname
          system = "x86_64-linux";
          targetSystem = "aarch64-linux";
          extraModules = [
            ./hosts/torii-chan/sd-image-installer.nix
            # Add U-Boot package via Overlays if necessary
            ({ config, pkgs, ... }: {
               nixpkgs.overlays = overlays;
            })
          ];
        };

        # 2. For Production / HDD operation
        "torii-chan" = lib.mkSystem {
          name = "torii-chan";
          system = "x86_64-linux"; # Using cross-compilation
          targetSystem = "aarch64-linux";
          extraModules = [
             ./hosts/torii-chan/fs-hdd.nix
             ./hosts/torii-chan/production-security.nix
          ];
        };

        # 3. For continuous development on SD card (No HDD)
        "torii-chan-sd-live" = lib.mkSystem {
          name = "torii-chan";
          system = "x86_64-linux";
          targetSystem = "aarch64-linux";
          extraModules = [
             ./hosts/torii-chan/fs-sd.nix
             ./hosts/torii-chan/production-security.nix
          ];
        };

        # 4. Tower Server (shosoin-tan)
        "shosoin-tan" = lib.mkSystem {
          name = "shosoin-tan";
          system = "x86_64-linux";
        };
      };
    };
}
