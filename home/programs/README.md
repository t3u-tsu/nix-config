# Programs Modules

Common user programs and CLI tools managed with Home Manager.

## Modules

| File | Description | Option |
| :--- | :--- | :--- |
| `cli-tools.nix` | CLI utilities (ripgrep, fd, bat, eza) and shell aliases. | `my.home.programs.cli-tools.enable` (Default: `true`) |
| `git.nix` | Git user identity, default branches, signing, and pull rebase defaults. | `my.home.programs.git.enable` (Default: `true`) |
| `ssh.nix` | SSH client host aliases and Nebula mesh addressing (`10.0.0.x`). | `my.home.programs.ssh.enable` (Default: `true`) |
| `llama.nix` | Local LLM inference server configuration. | `my.home.programs.llama.enable` (Default: `false`) |
| `default.nix` | Program module aggregator. | — |

## References

- Mesh network topology: [`docs/architecture/network-topology.md`](../../docs/architecture/network-topology.md)
