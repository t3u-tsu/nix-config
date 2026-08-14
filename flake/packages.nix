{ config, lib, ... }:
{
  perSystem =
    { system, ... }:
    {
      packages = lib.optionalAttrs (system == "x86_64-linux") {
        # Installer ISO for torii-chan's failover VPS (ConoHa is x86_64).
        # Kept as a package, not a nixosConfiguration: nix flake check would
        # fail on the ISO's fileSystems / grub assertions.
        torii-chan-vps-iso =
          (config.flake.lib.mkLib.mkSystem {
            name = "torii-chan";
            username = "t3u";
            system = "x86_64-linux";
            profile = "gateway";
            extraModules = [ ../hosts/torii-chan/vps-installer.nix ];
          }).config.system.build.images.iso-installer;
      };
    };
}
