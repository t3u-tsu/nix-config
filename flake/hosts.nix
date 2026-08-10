# flake/hosts.nix - nixosConfigurations for all hosts
{ config, ... }:
let
  mkLib = config.flake.lib.mkLib;
in
{
  flake.nixosConfigurations = {

    # === torii-chan (Nebula gateway / Lighthouse + DDNS) ===
    #
    # The same role runs on the physical SBC or the failover VPS, one at a time.
    # Both share hostname `torii-chan` and identical secrets so peers keep using
    # torii-chan.t3u.uk without reconfiguration.

    # SD installer image: no production services, temp password + relaxed SSH.
    # Build with ./hosts/torii-chan/build-sd-image.sh
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

    # Production on the physical SBC (HDD root)
    "torii-chan-hdd" = mkLib.mkSystem {
      name = "torii-chan";
      username = "t3u";
      system = "aarch64-linux";
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
    "shosoin-tan" = mkLib.mkSystem {
      name = "shosoin-tan";
      username = "t3u";
      system = "x86_64-linux";
    };

    "kagutsuchi-sama" = mkLib.mkSystem {
      name = "kagutsuchi-sama";
      username = "t3u";
      system = "x86_64-linux";
    };

    "sando-kun" = mkLib.mkSystem {
      name = "sando-kun";
      username = "t3u";
      system = "x86_64-linux";
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
