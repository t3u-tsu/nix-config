# NixOS System Modules (`nixos/`)

System-level NixOS configuration modules, aggregated in [nixos/default.nix](default.nix) and applied across all fleet machines.

## Modules

| Directory | Scope & Responsibilities |
| :--- | :--- |
| [base/](base/README.md) | OS baseline: users, Nix daemon settings, private Flake input, NTP time sync, locale (`ja_JP.UTF-8` / `en_US.UTF-8`), and console keymap. |
| [security/](security/README.md) | agenix and agenix-rekey secrets integration. |
| [networking/](networking/README.md) | Nebula mesh overlay network and LAN routing optimizations. |
| [environment/](environment/README.md) | Modular system package categories (`my.packages.*`). |
| [hardware/](hardware/README.md) | Hardware drivers, NVIDIA hybrid graphics / PRIME offload, and storage diagnostic tools. |
| [dev-tools/](dev-tools/README.md) | Hardware probe udev rules (WCH-LinkE) and installer utilities. |
| [profiles/](profiles/README.md) | Machine role profiles (`desktop`, `gateway`, `sbc`, `tower-server`). |
| [services/](services/README.md) | Fleet services: Minecraft, Discord bridge, Restic backup, desktop daemons. |
| [virtualisation/](virtualisation/README.md) | Container environments (Distrobox / Podman) and MicroVM runner. |

## References

- System evaluation architecture: [docs/architecture/overview.md](../docs/architecture/overview.md)
- Custom module options (`my.*`): [docs/architecture/flake-and-modules.md](../docs/architecture/flake-and-modules.md)
