# SBC Profile (`nixos/profiles/sbc/`)

Constraint layer for resource-constrained Single-Board Computers (e.g. Orange Pi Zero 3 with 1 GB RAM). No host selects it as a `profile`; [hosts/torii-chan/sbc.nix](../../../hosts/torii-chan/sbc.nix) imports it and the `torii-chan` SBC variants attach that module through `extraModules`.

## Key Optimizations

| Category | Setting | Description |
| :--- | :--- | :--- |
| **Build Sandbox** | `nix.settings.sandbox = false` | Disables build sandboxing to work around missing `user_namespaces` support on embedded kernels. |
| **Syscall Filter** | `nix.settings.filter-syscalls = false` | Disables seccomp BPF syscall filtering on unsupported kernel revisions. |
| **Memory & Swap** | 4 GB swapfile (`/var/lib/swapfile`) | Pre-allocates swap space to prevent out-of-memory errors during Nix Flake evaluations. |
| **Kernel Swappiness** | `vm.swappiness = 10` | Minimizes swap disk thrashing while retaining headroom for memory spikes. |

## References

- Orange Pi Zero 3 hardware guide: [docs/hardware/orange-pi-zero3.md](../../../docs/hardware/orange-pi-zero3.md)
- SBC host deployment: [hosts/torii-chan/](../../../hosts/torii-chan/README.md)
