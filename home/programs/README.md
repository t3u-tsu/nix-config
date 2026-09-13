# Programs Modules

Common workstation tools managed via Home Manager.

## Modules

- **`cli-tools.nix`**: Modern CLI replacements plus the `ls`/`ll`/`la`/`tree` shell aliases.
- **`git.nix`**: Git configuration — identity, GPG-signed commits, rebase-on-pull.
- **`ssh.nix`**: SSH client config — fleet host entries over the Nebula mesh (`10.0.0.x`).
- **`llama.nix`**: Local LLM inference server behind `my.services.llama.enable`.
- **`default.nix`**: Imports the program modules.
