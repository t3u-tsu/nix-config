# Home Modules

User-specific configurations managed via Home Manager.

## Modules

- **`shell/`**: Shell configuration (Zsh (`shell.nix`), Starship (`starship.nix`), Atuin (`atuin.nix`)).
- **`programs/`**: Workstation tools (CLI tools (`cli-tools.nix`), Git (`git.nix`), SSH (`ssh.nix`)).
- **`desktop/`**: User-specific desktop environment configuration (browsers, wm, themes).
- **`default.nix`**: Imports all base home modules.
