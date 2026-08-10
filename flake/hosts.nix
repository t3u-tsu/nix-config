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

    # === torii-chan (Nebula gateway / Lighthouse + DDNS) ===
    #
    # The same role runs on the physical SBC or the failover VPS, one at a time.
    # Both share hostname `torii-chan` and identical secrets so peers keep using
    # torii-chan.t3u.uk without reconfiguration.

    # 1. SD installer image (aarch64 native, built on x86_64 via QEMU binfmt).
    #    stage: installer — no production services, temp password + relaxed SSH.
    #    Build with ./hosts/torii-chan/build-sd-image.sh
    "torii-chan-sd-installer" = mkLib.mkSystem {
      name = "torii-chan";
      username = "t3u";
      system = "aarch64-linux";
      extraModules = [
        ../hosts/torii-chan/sd-installer.nix
        ../hosts/torii-chan/sbc.nix
        ../hosts/torii-chan/fs-sd.nix
      ];
    };

    # 2. Production on the physical SBC (HDD root)
    "torii-chan-hdd" = mkLib.mkSystem {
      name = "torii-chan";
      username = "t3u";
      system = "aarch64-linux";
      extraModules = [
        ../hosts/torii-chan/sbc.nix
        ../hosts/torii-chan/fs-hdd.nix
      ];
    };

    # 3. Production on SD card (no HDD)
    "torii-chan-sd" = mkLib.mkSystem {
      name = "torii-chan";
      username = "t3u";
      system = "aarch64-linux";
      extraModules = [
        ../hosts/torii-chan/sbc.nix
        ../hosts/torii-chan/fs-sd.nix
      ];
    };

    # === torii-chan (VPS failover host) ===
    #
    # Same role as above, on a VPS. When active, its DDNS updates
    # torii-chan.t3u.uk to the VPS public IP and peers reconnect automatically.
    # Adjust the placeholders in ../hosts/torii-chan/vps.nix to your provider.
    "torii-chan-vps" = mkLib.mkSystem {
      name = "torii-chan";
      username = "t3u";
      system = "x86_64-linux";
      extraModules = [
        ../hosts/torii-chan/vps.nix
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
