# Security Modules (`nixos/security/`)

System secrets management, cryptographic key bootstrapping, and permission policies.

## Modules

| File | Purpose | Notes |
| :--- | :--- | :--- |
| [sops.nix](sops.nix) | SOPS secret decryption via `sops-nix`. Automatically extracts host Age private key from `/etc/ssh/ssh_host_ed25519_key` during system activation (`0-sops-key-import`). | Sets `sops.age.generateKey = false`. |
| [default.nix](default.nix) | Security module aggregator. | — |

## References

- SOPS secrets directory: [secrets/](../../secrets/README.md)
- Secret management & key lifecycle: [docs/operations/secret-management.md](../../docs/operations/secret-management.md)
- Secrets troubleshooting: [docs/troubleshooting/secrets-and-auth.md](../../docs/troubleshooting/secrets-and-auth.md)
