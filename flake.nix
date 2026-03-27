{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
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
    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    minecraft-discord-bridge = {
      url = "github:t3u-tsu/minecraft-discord-bridge";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-shell = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    awww = {
      url = "git+https://codeberg.org/LGFae/awww";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dracula-alacritty = {
      url = "github:dracula/alacritty";
      flake = false;
    };
    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, disko, sops-nix, nix-minecraft, ... }@inputs:
    let
      # Overlays for cross-compilation, Minecraft, and Unstable packages
      overlays = [
        nix-minecraft.overlay
        inputs.niri.overlays.niri
        (final: prev: {
          # Access unstable packages via 'unstable' attribute
          unstable = import nixpkgs-unstable {
            inherit (prev.stdenv.hostPlatform) system;
            config.allowUnfree = true;
          };
          
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
      lib = import ./lib {
        inherit nixpkgs inputs home-manager disko sops-nix nix-minecraft overlays;
      };
    in
    {
      inherit lib;
      nixosConfigurations = {
        # 1. For SD card creation (No Disko, uses standard modules)
        "torii-chan-sd" = lib.mkSystem {
          name = "torii-chan"; # Same hostname
          username = "t3u";
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
          username = "t3u";
          system = "aarch64-linux";
          extraModules = [
             ./hosts/torii-chan/fs-hdd.nix
             ./hosts/torii-chan/production-security.nix
          ];
        };

        # 3. For continuous development on SD card (No HDD)
        "torii-chan-sd-live" = lib.mkSystem {
          name = "torii-chan";
          username = "t3u";
          system = "aarch64-linux";
          extraModules = [
             ./hosts/torii-chan/fs-sd.nix
             ./hosts/torii-chan/production-security.nix
          ];
        };

        # 4. Tower Server (shosoin-tan)
        "shosoin-tan" = lib.mkSystem {
          name = "shosoin-tan";
          username = "t3u";
          system = "x86_64-linux";
        };

        # 5. Tower Server (kagutsuchi-sama)
        "kagutsuchi-sama" = lib.mkSystem {
          name = "kagutsuchi-sama";
          username = "t3u";
          system = "x86_64-linux";
        };

        # 6. Tower Server (sando-kun)
        "sando-kun" = lib.mkSystem {
          name = "sando-kun";
          username = "t3u";
          system = "x86_64-linux";
        };

        # 7. Desktop PC (BrokenPC)
        "BrokenPC" = lib.mkSystem {
          name = "BrokenPC";
          username = "t3u";
          system = "x86_64-linux";
        };
      };
    };
}
