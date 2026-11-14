# Home Modules (`home/`)

User-specific configurations managed with Home Manager.

## Modules

| File | Description | Options |
| :--- | :--- | :--- |
| [default.nix](default.nix) | Aggregates base home modules. | Imported by [lib/default.nix](../lib/default.nix) (`mkSystem`) |
| [agenix.nix](agenix.nix) | Sets the user SSH key as the agenix-rekey identity and reads home secrets from `secrets/rekeyed/home/`. | Always active |
| [shell/](shell/README.md) | Interactive shell environment, prompt, and command history. | Always active |
| [programs/](programs/README.md) | CLI tools, Git, and SSH client. | Always active |
| [desktop/](desktop/README.md) | Desktop environment (Wayland compositor, shell, browsers, apps). | `my.home.desktop.enable`, `my.home.desktop.full.enable` |

## References

- System evaluation architecture: [docs/architecture/overview.md](../docs/architecture/overview.md)
- Custom module options (`my.*`): [docs/architecture/flake-and-modules.md](../docs/architecture/flake-and-modules.md)
