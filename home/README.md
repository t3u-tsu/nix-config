# Home Modules

User-specific configurations managed via Home Manager.

## Modules

- **`shell/`**: Shell configuration (Zsh (`shell.nix`), Starship (`starship.nix`), Atuin (`atuin.nix`)).
- **`programs/`**: Workstation tools (CLI tools (`cli-tools.nix`), Git (`git.nix`), SSH (`ssh.nix`), llama.cpp inference server (`llama.nix`)).
- **`desktop/`**: User-specific desktop environment configuration (browsers, wm, themes).
- **`sops.nix`**: SOPS age key setup (generates the age private key from the daily SSH key).
- **`default.nix`**: Imports all base home modules.
