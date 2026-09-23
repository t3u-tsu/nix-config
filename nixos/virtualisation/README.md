# Virtualisation Modules

Virtualisation and container support.

## Modules

- **`distrobox.nix`**: Rootless container environment behind `my.virtualisation.distrobox.enable` (Podman with Docker compatibility).
- **`microvm.nix`**: MicroVM guest runner behind `my.virtualisation.microvm.enable` (imports `microvm.nixosModules.host`).
- **`default.nix`**: Imports the virtualisation modules.
