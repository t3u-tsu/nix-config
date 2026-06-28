# Core Modules

The foundational infrastructure of the system configuration.

## Modules

- **`user.nix`**: Abstracted primary user definition (`my.user.name`).
- **`nix.nix`**: Nix settings, experimental features, garbage collection, and binary caches (substituters).
- **`networking.nix`**: Basic network configuration and Hostname management.
- **`wireguard.nix`**: Common retry logic and automation for WireGuard interfaces.
- **`sops.nix`**: Master SOPS configuration for secret management.
- **`time.nix`**: Timezone and clock settings.
- **`default.nix`**: Common imports for all hosts.
