{
  config,
  inputs,
  lib,
  ...
}:
let
  mkLib = import ../lib {
    inherit inputs;
    overlays = lib.attrValues config.flake.overlays;
  };

  # Fleet declaration: one entry per host directory in hosts/. Hosts running
  # the same role on multiple boot media or platforms list them under
  # variants; each variant becomes a "<name>-<variant>" configuration.
  fleet = {
    shosoin-tan = {
      system = "x86_64-linux";
      profile = "tower-server";
    };
    kagutsuchi-sama = {
      system = "x86_64-linux";
      profile = "tower-server";
    };
    sando-kun = {
      system = "x86_64-linux";
      profile = "tower-server";
    };
    BrokenPC = {
      system = "x86_64-linux";
      profile = "desktop";
    };
    x1c7 = {
      system = "x86_64-linux";
      profile = "desktop";
    };

    # Nebula gateway / Lighthouse + DDNS. The same role runs on the physical
    # SBC or the failover VPS, one at a time.
    torii-chan = {
      profile = "gateway";
      variants = {
        # SD installer image: no production services, temp password + relaxed SSH.
        # Build with ./hosts/torii-chan/build-sd-image.ysh
        sd-installer = {
          system = "aarch64-linux";
          extraModules = [
            ../hosts/torii-chan/sd-installer.nix
            ../hosts/torii-chan/sbc.nix
            ../hosts/torii-chan/fs-sd.nix
          ];
        };
        hdd = {
          system = "aarch64-linux";
          extraModules = [
            ../hosts/torii-chan/sbc.nix
            ../hosts/torii-chan/fs-hdd.nix
          ];
        };
        sd = {
          system = "aarch64-linux";
          extraModules = [
            ../hosts/torii-chan/sbc.nix
            ../hosts/torii-chan/fs-sd.nix
          ];
        };
        vps = {
          system = "x86_64-linux";
          extraModules = [ ../hosts/torii-chan/vps.nix ];
        };
      };
    };
  };

  mkConfigs =
    name: host:
    if host ? variants then
      lib.mapAttrs' (
        variant: cfg:
        lib.nameValuePair "${name}-${variant}" (
          mkLib.mkSystem (removeAttrs host [ "variants" ] // cfg // { inherit name; })
        )
      ) host.variants
    else
      { ${name} = mkLib.mkSystem (host // { inherit name; }); };
in
{
  flake.nixosConfigurations = lib.concatMapAttrs mkConfigs fleet;
}
