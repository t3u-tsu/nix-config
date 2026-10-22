# Shell Modules

Interactive shell environment managed via Home Manager.

## Modules

| File | Description | Option |
| :--- | :--- | :--- |
| `shell.nix` | Zsh configuration: completion engine, autosuggestions, syntax highlighting, and history limits. | `my.home.shell.enable` (Default: `true`) |
| `pure.nix` | Minimalist Pure prompt integration via flake input with custom zstyles. | Enabled with `shell.nix` |
| `atuin.nix` | Atuin shell history SQLite database and sync client. | `my.home.shell.atuin.enable` (Default: `true`) |
| `default.nix` | Shell module aggregator. | — |
