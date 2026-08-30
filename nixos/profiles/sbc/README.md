# SBC Profile

Profile for low-memory single-board computers (e.g. Orange Pi Zero 3).

## Features

- Nix sandboxing and seccomp filtering disabled (legacy kernels lack `user_namespaces` / seccomp BPF support).
- 4GB swapfile at `/var/lib/swapfile` with `vm.swappiness = 10` for stable builds on low RAM.