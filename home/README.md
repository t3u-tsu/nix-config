# Home Modules

User-specific configurations managed via Home Manager.

## Modules

- [`shell/`](shell/): Interactive shell, prompt and history.
- [`programs/`](programs/): Workstation tools shared by all hosts.
- [`desktop/`](desktop/): Desktop environment configuration — lightweight core plus an opt-in full stack.
- **`sops.nix`**: SOPS age key setup (generates the age private key from the daily SSH key).
- **`default.nix`**: Imports all base home modules.

## References
- System evaluation architecture: [`docs/architecture/overview.md`](../docs/architecture/overview.md)
- Custom module options (`my.*`): [`docs/architecture/flake-and-modules.md`](../docs/architecture/flake-and-modules.md)
