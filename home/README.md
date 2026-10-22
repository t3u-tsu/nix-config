# Home Modules

User-specific configurations managed via Home Manager.

## Modules

| Directory / File | Description |
| :--- | :--- |
| [`shell/`](shell/README.md) | Interactive shell environment, prompt, and command history. |
| [`programs/`](programs/README.md) | Common CLI tools, Git, SSH client, and local LLM services. |
| [`desktop/`](desktop/README.md) | Desktop environment (Wayland compositor, shell, browsers, apps). |
| `sops.nix` | SOPS age key derivation from user SSH key. |
| `default.nix` | Aggregates base home modules. |

## References

- System evaluation architecture: [`docs/architecture/overview.md`](../docs/architecture/overview.md)
- Custom module options (`my.*`): [`docs/architecture/flake-and-modules.md`](../docs/architecture/flake-and-modules.md)
