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

  # Fleet declaration: one entry per configured host in hosts/ (not _template).
  # A host whose role runs on several boot media or platforms lists them under
  # variants; each becomes a "<name>-<variant>" configuration.
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

  # Variant fields override host-level ones, except extraModules, which are
  # appended to the host-level list rather than replacing it.
  mkHostConfigs =
    name: host:
    let
      mkConfig =
        variant:
        mkLib.mkSystem (
          lib.removeAttrs host [ "variants" ]
          // variant
          // {
            inherit name;
            extraModules = (host.extraModules or [ ]) ++ (variant.extraModules or [ ]);
          }
        );
    in
    if host ? variants then
      lib.mapAttrs' (variant: cfg: lib.nameValuePair "${name}-${variant}" (mkConfig cfg)) host.variants
    else
      { ${name} = mkConfig { }; };

  configurations = lib.concatMapAttrs mkHostConfigs fleet;

  # listToAttrs keeps the first duplicate, so a name collision would silently
  # drop a configuration.
  expectedConfigCount = lib.foldl' lib.add 0 (
    lib.mapAttrsToList (
      _: host: if host ? variants then lib.length (lib.attrNames host.variants) else 1
    ) fleet
  );
in
{
  flake.nixosConfigurations =
    assert lib.length (lib.attrNames configurations) == expectedConfigCount;
    configurations;
}
