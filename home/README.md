# Home Modules

User-specific configurations managed via Home Manager.

## Modules

- **`shell/`**: Shell configuration (Zsh, Pure prompt, Atuin).
- **`programs/`**: Workstation tools (CLI tools, Git, SSH, llama.cpp).
- **`desktop/`**: Desktop environment configuration (browsers, Niri, Noctalia, themes).
- **`sops.nix`**: SOPS age key setup (generates the age private key from the daily SSH key).
- **`default.nix`**: Imports all base home modules.
