# Program Modules (`home/programs/`)

Common user programs and CLI tools managed with Home Manager.

## Modules

| File | Description | Options / Notes |
| :--- | :--- | :--- |
| [cli-tools.nix](cli-tools.nix) | CLI utilities (e.g. `bat`, `eza`, `ripgrep`, `fd`, `fzf`, `zoxide`). | Always enabled |
| [direnv/](direnv/default.nix) | `direnv` + `nix-direnv` background reload, desktop notifications, and status aliases. | Always enabled |
| [git.nix](git.nix) | Git identity, Git LFS, and pull rebase defaults. | Always enabled |
| [ssh.nix](ssh.nix) | SSH client host aliases and Nebula mesh addressing (`10.0.0.x`). | Always enabled |
| [default.nix](default.nix) | Program module aggregator. | — |

## References

- Mesh network topology: [docs/architecture/network-topology.md](../../docs/architecture/network-topology.md)
- System package groups: [nixos/environment/](../../nixos/environment/README.md)
