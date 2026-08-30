# Programs Modules

Common workstation tools managed via Home Manager.

## Modules

- **`cli-tools.nix`**: Modern CLI tools — bat, eza, fzf, zoxide, fd, ripgrep, yazi, tealdeer, direnv.
- **`git.nix`**: Git configuration — GPG-signed commits, rebase-on-pull, aliases.
- **`ssh.nix`**: SSH client config — host entries for the fleet (`torii-chan`, `sando-kun`, `kagutsuchi-sama`, `shosoin-tan`, `BrokenPC`) over the Nebula mesh (`10.0.0.x`).
- **`llama.nix`**: llama.cpp inference server behind `my.services.llama.enable`.
- **`default.nix`**: Imports the program modules.