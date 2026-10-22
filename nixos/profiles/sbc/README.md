# SBC Profile (`nixos/profiles/sbc/`)

System profile optimized for resource-constrained Single-Board Computers (e.g. Orange Pi Zero 3 with 1 GB RAM).

## Key Optimizations

| Category | Setting | Description |
| :--- | :--- | :--- |
| **Build Sandbox** | `nix.settings.sandbox = false` | Disables build sandboxing to work around missing `user_namespaces` support on embedded kernels. |
| **Syscall Filter** | `nix.settings.filter-syscalls = false` | Disables seccomp BPF syscall filtering on unsupported kernel revisions. |
| **Memory & Swap** | 4 GB swapfile (`/var/lib/swapfile`) | Pre-allocates swap space to prevent out-of-memory errors during Nix Flake evaluations. |
| **Kernel Swappiness** | `vm.swappiness = 10` | Minimizes unnecessary swap disk thrashing while retaining headroom for memory spikes. |

## References

- Orange Pi Zero 3 hardware guide: [`docs/hardware/orange-pi-zero3.md`](../../../docs/hardware/orange-pi-zero3.md)
- SBC host deployment: [`hosts/torii-chan/`](../../../hosts/torii-chan/README.md)
