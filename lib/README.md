# Library Helpers (`lib/`)

Helper functions and shared assets for NixOS system evaluations.

## Modules & Helpers

| File | Function / Export | Description |
| :--- | :--- | :--- |
| `default.nix` | `mkSystem` | Constructs a `nixosSystem` configuration with injected `specialArgs`, host defaults, and profile imports; also acts as the library index for flake modules. |
| `palette.nix` | `palette` | Vesper color palette (hex strings) shared by Home Manager desktop themes and greetd. |

## `mkSystem` Evaluation API

```nix
mkSystem {
  name,                     # Host directory name in hosts/${name}
  system,                   # Target platform ("x86_64-linux" | "aarch64-linux")
  username ? "t3u",         # Primary user account name (default: "t3u")
  profile,                  # Base profile name in nixos/profiles/${profile}
  extraModules ? []         # Additional modules evaluated last for overriding settings
}
```

- Injects flake `inputs` into `specialArgs`.
- Imports `nixos/profiles/${profile}` and `hosts/${name}/default.nix`.
- Evaluates `extraModules` last, allowing targeted per-host overrides.

## References

- System evaluation architecture: [`docs/architecture/overview.md`](../docs/architecture/overview.md)
- Flake structure and module options: [`docs/architecture/flake-and-modules.md`](../docs/architecture/flake-and-modules.md)
