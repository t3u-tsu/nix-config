# Home Modules

User-specific configurations managed via Home Manager.

## Modules

- **`shell/`**: Interactive shell, prompt and history.
- **`programs/`**: Workstation tools shared by all hosts.
- **`desktop/`**: Desktop environment configuration — lightweight core plus an opt-in full stack.
- **`sops.nix`**: SOPS age key setup (generates the age private key from the daily SSH key).
- **`default.nix`**: Imports all base home modules.
