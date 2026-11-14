# NixOS System Modules (`nixos/`)

System-level NixOS configuration modules, aggregated in [nixos/default.nix](default.nix) and applied across all fleet machines.

## Modules

| File | Description | Options |
| :--- | :--- | :--- |
| [default.nix](default.nix) | Top-level aggregator importing all NixOS module directories. | Imported by [lib/default.nix](../lib/default.nix) (`mkSystem`) |
| [base/](base/README.md) | OS baseline: users, Nix daemon settings, private Flake input, NTP time sync, locale (`ja_JP.UTF-8` / `en_US.UTF-8`), and console keymap. | Always active (base layer) |
| [security/](security/README.md) | agenix and agenix-rekey secrets integration. | Always active (base layer) |
| [networking/](networking/README.md) | Nebula mesh overlay network and LAN routing optimizations. | `my.networking.nebula.*` |
| [environment/](environment/README.md) | Modular system package categories. | `my.packages.*` |
| [hardware/](hardware/README.md) | Hardware drivers, NVIDIA hybrid graphics / PRIME offload, and storage diagnostic tools. | `my.hardware.*` |
| [dev-tools/](dev-tools/README.md) | Hardware probe udev rules (WCH-LinkE) and installer utilities. | `my.devTools.*` |
| [profiles/](profiles/README.md) | Machine role profiles (`desktop`, `gateway`, `tower-server`); `sbc/` is a constraint layer imported by [hosts/torii-chan/sbc.nix](../hosts/torii-chan/sbc.nix). | Selected via `profile` in [flake/hosts.nix](../flake/hosts.nix) |
| [services/](services/README.md) | Fleet services: Minecraft, Discord bridge, Restic backup, desktop daemons. | `my.services.*` |
| [virtualisation/](virtualisation/README.md) | Container environments (Distrobox / Podman) and MicroVM runner. | `my.virtualisation.*` |

## References

- System evaluation architecture: [docs/architecture/overview.md](../docs/architecture/overview.md)
- Custom module options (`my.*`): [docs/architecture/flake-and-modules.md](../docs/architecture/flake-and-modules.md)
