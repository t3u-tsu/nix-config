{ config, ... }:
let
  mkLib = config.flake.lib.mkLib;
in
{
  flake.nixosConfigurations = {

    # === torii-chan (Nebula gateway / Lighthouse + DDNS) ===
    # The same role runs on the physical SBC or the failover VPS, one at a time.

    # SD installer image: no production services, temp password + relaxed SSH.
    # Build with ./hosts/torii-chan/build-sd-image.sh
    "torii-chan-sd-installer" = mkLib.mkSystem {
      name = "torii-chan";
      username = "t3u";
      system = "aarch64-linux";
      profile = "gateway";
      extraModules = [
        ../hosts/torii-chan/sd-installer.nix
        ../hosts/torii-chan/sbc.nix
        ../hosts/torii-chan/fs-sd.nix
      ];
    };

    # Production on the physical SBC (HDD root)
    "torii-chan-hdd" = mkLib.mkSystem {
      name = "torii-chan";
      username = "t3u";
      system = "aarch64-linux";
      profile = "gateway";
      extraModules = [
        ../hosts/torii-chan/sbc.nix
        ../hosts/torii-chan/fs-hdd.nix
      ];
    };

    # Production on SD card (no HDD)
    "torii-chan-sd" = mkLib.mkSystem {
      name = "torii-chan";
      username = "t3u";
      system = "aarch64-linux";
      profile = "gateway";
      extraModules = [
        ../hosts/torii-chan/sbc.nix
        ../hosts/torii-chan/fs-sd.nix
      ];
    };

    # VPS failover host
    "torii-chan-vps" = mkLib.mkSystem {
      name = "torii-chan";
      username = "t3u";
      system = "x86_64-linux";
      profile = "gateway";
      extraModules = [
        ../hosts/torii-chan/vps.nix
      ];
    };

    # === Tower Servers ===
    "shosoin-tan" = mkLib.mkSystem {
      name = "shosoin-tan";
      username = "t3u";
      system = "x86_64-linux";
      profile = "tower-server";
    };

    "kagutsuchi-sama" = mkLib.mkSystem {
      name = "kagutsuchi-sama";
      username = "t3u";
      system = "x86_64-linux";
      profile = "tower-server";
    };

    "sando-kun" = mkLib.mkSystem {
      name = "sando-kun";
      username = "t3u";
      system = "x86_64-linux";
      profile = "tower-server";
    };

    # === Desktop ===
    "BrokenPC" = mkLib.mkSystem {
      name = "BrokenPC";
      username = "t3u";
      system = "x86_64-linux";
      profile = "desktop";
    };
  };
}
