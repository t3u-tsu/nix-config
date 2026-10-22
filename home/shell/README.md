# Shell Modules (`home/shell/`)

Interactive shell environment managed with Home Manager.

## Modules

| File | Description | Options / Notes |
| :--- | :--- | :--- |
| [shell.nix](shell.nix) | Zsh configuration: completion engine, autosuggestions, syntax highlighting, and history limits. | Always enabled |
| [pure.nix](pure.nix) | Pure prompt integration via `pkgs.unstable.pure-prompt` with custom zstyles. | Always enabled |
| [atuin.nix](atuin.nix) | Atuin shell history SQLite database and sync client. | Always enabled |
| [default.nix](default.nix) | Shell module aggregator. | — |

## References

- System baseline packages and default shell: [nixos/environment/base.nix](../../nixos/environment/base.nix)
- User CLI tools: [home/programs/](../programs/README.md)
- Home Manager configuration entry: [home/default.nix](../default.nix)
