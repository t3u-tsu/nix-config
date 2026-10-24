# Security Modules (`nixos/security/`)

System secrets management, cryptographic key bootstrapping, and permission policies.

## Modules

| File | Description | Options / Notes |
| :--- | :--- | :--- |
| [agenix.nix](agenix.nix) | Agenix-rekey secret decryption via the host SSH identity; rekeys `secrets/master/hosts/<hostname>/` into `secrets/rekeyed/hosts/<hostname>/`. | Sets `age.identityPaths` and declares `user_password_hash` / `root_password_hash` |
| [default.nix](default.nix) | Security module aggregator. | — |

## References

- Encrypted secrets directory: [secrets/](../../secrets/README.md)
- Secret management & key lifecycle: [docs/operations/secret-management.md](../../docs/operations/secret-management.md)
- Secrets troubleshooting: [docs/troubleshooting/secrets-and-auth.md](../../docs/troubleshooting/secrets-and-auth.md)
