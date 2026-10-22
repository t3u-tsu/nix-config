# Shell Modules

Interactive shell environment managed with Home Manager.

## Modules

| File | Description | Option |
| :--- | :--- | :--- |
| [shell.nix](shell.nix) | Zsh configuration: completion engine, autosuggestions, syntax highlighting, and history limits. | Always enabled |
| [pure.nix](pure.nix) | Pure prompt integration via `pkgs.unstable.pure-prompt` with custom zstyles. | Always enabled |
| [atuin.nix](atuin.nix) | Atuin shell history SQLite database and sync client. | Always enabled |
| [default.nix](default.nix) | Shell module aggregator. | — |
