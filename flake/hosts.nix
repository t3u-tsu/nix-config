# flake/hosts.nix - nixosConfigurations for all hosts
{
  self,
  inputs,
  config,
  lib,
  ...
}:
let
  mkLib = import ../lib {
    inherit (inputs)
      nixpkgs
      home-manager
      sops-nix
      nix-minecraft
      ;
    inherit inputs;
    overlays = lib.attrValues (config.flake.overlays or { });
  };
in
{
  flake.nixosConfigurations = {

    # === torii-chan (Orange Pi Zero 3 SBC) ===

    # 1. SD card image builder (cross-compile from x86_64)
    "torii-chan-sd" = mkLib.mkSystem {
      name = "torii-chan";
      username = "t3u";
      system = "x86_64-linux";
      targetSystem = "aarch64-linux";
      extraModules = [
        ../hosts/torii-chan/sd-image-installer.nix
      ];
    };

    # 2. Production (HDD operation)
    "torii-chan" = mkLib.mkSystem {
      name = "torii-chan";
      username = "t3u";
      system = "aarch64-linux";
      extraModules = [
        ../hosts/torii-chan/fs-hdd.nix
        ../hosts/torii-chan/production-security.nix
      ];
    };

    # 3. Development on SD card (no HDD)
    "torii-chan-sd-live" = mkLib.mkSystem {
      name = "torii-chan";
      username = "t3u";
      system = "aarch64-linux";
      extraModules = [
        ../hosts/torii-chan/fs-sd.nix
        ../hosts/torii-chan/production-security.nix
      ];
    };

    # === Tower Servers ===

    # 4. shosoin-tan
    "shosoin-tan" = mkLib.mkSystem {
      name = "shosoin-tan";
      username = "t3u";
      system = "x86_64-linux";
    };

    # 5. kagutsuchi-sama
    "kagutsuchi-sama" = mkLib.mkSystem {
      name = "kagutsuchi-sama";
      username = "t3u";
      system = "x86_64-linux";
    };

    # 6. sando-kun
    "sando-kun" = mkLib.mkSystem {
      name = "sando-kun";
      username = "t3u";
      system = "x86_64-linux";
    };

    # === Desktop ===

    # 7. BrokenPC
    "BrokenPC" = mkLib.mkSystem {
      name = "BrokenPC";
      username = "t3u";
      system = "x86_64-linux";
      profile = "desktop";
    };
  };
}
