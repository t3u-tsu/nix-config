# lib/ — mkSystem

Helper library for building NixOS systems.

## mkSystem

`mkSystem { name, system, username ? "t3u", profile, extraModules ? [] }` builds a `nixosSystem` configuration:

- Passes `inputs` to every module via `specialArgs`.
- Applies the role profile (`../nixos/profiles/${profile}`) automatically.
- Imports the host entry (`../hosts/${name}/default.nix`) and any `extraModules` (evaluated last, so they can override earlier settings).

Used by `flake/hosts.nix` for every `nixosConfigurations` entry.