# Development Tools (System Level)

System-wide configuration for development hardware and tooling.
Imported for all hosts via `nixos/default.nix`; enabled per-host with
`my.dev-tools.enable`.

## Modules

- **`default.nix`**: Defines the `my.dev-tools.enable` category flag and imports the modules.
- **`wch-linke.nix`**: WCH-LinkE programming/debugging udev rules.
- **`ventoy.nix`**: Approves the insecure Ventoy package.
  Ventoy ships binary blobs that cannot be trusted to be malware-free (nixpkgs#404663),
  so the package is marked insecure and requires `nixpkgs.config.permittedInsecurePackages`.