# Security Modules

Security and secret management.

## Modules

- **`sops.nix`**: SOPS integration via `sops-nix`.
  - Per-host secrets from `secrets/hosts/<hostname>.yaml` (password hashes, SSH keys, Nebula certs).
  - Age key is **derived from the SSH host key** at activation (`0-sops-key-import` writes `/var/lib/sops-nix/key.txt`), so freshly flashed images decrypt without manual key placement — as long as the SSH host key exists (i.e. `services.openssh` is enabled).
  - `sops.age.generateKey = false` is required: a random age key cannot decrypt host-key-encrypted secrets.
- **`default.nix`**: Imports the security modules.