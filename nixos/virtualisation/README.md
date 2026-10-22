# Virtualisation Modules (`nixos/virtualisation/`)

Container runtimes and lightweight virtual machine guest environments.

## Modules

| File | Description | Options / Notes |
| :--- | :--- | :--- |
| [distrobox.nix](distrobox.nix) | Rootless container environment using Podman with Docker CLI compatibility. | `my.virtualisation.distrobox.enable` |
| [microvm.nix](microvm.nix) | MicroVM.nix host integration for lightweight virtual machines. | `my.virtualisation.microvm.enable` |
| [default.nix](default.nix) | Virtualisation module aggregator. | — |

## References

- MicroVM flake upstream: [astro/microvm.nix](https://github.com/astro/microvm.nix)
- User development containers (Unity via Distrobox): [home/desktop/dev-tools/unity.nix](../../home/desktop/dev-tools/unity.nix)
- System evaluation architecture: [docs/architecture/overview.md](../../docs/architecture/overview.md)
- Custom module options (`my.*`): [docs/architecture/flake-and-modules.md](../../docs/architecture/flake-and-modules.md)
