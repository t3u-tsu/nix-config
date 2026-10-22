# Virtualisation Modules (`nixos/virtualisation/`)

Container runtimes and lightweight virtual machine guest environments.

## Modules

| File | Purpose | Option |
| :--- | :--- | :--- |
| [distrobox.nix](distrobox.nix) | Rootless container environment using Podman with Docker CLI compatibility. | `my.virtualisation.distrobox.enable` |
| [microvm.nix](microvm.nix) | Lightweight MicroVM host runner integration using [microvm.nix](microvm.nix). | `my.virtualisation.microvm.enable` |
| [default.nix](default.nix) | Virtualisation module aggregator. | — |
