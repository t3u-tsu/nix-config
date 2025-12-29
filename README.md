# My NixOS Fleet

This repository manages multiple NixOS configurations using Flakes. It is designed for cross-compilation and secure secret management.

## Directory Structure

```text
.
├── flake.nix           # Entry point for the configuration
├── hosts/              # Host-specific configurations
│   └── torii-chan/     # Orange Pi Zero3 configuration
├── lib/                # Common library functions for mkSystem
└── secrets/            # Encrypted secrets (SOPS)
    └── secrets.yaml
```

## Hosts

| Hostname | Hardware | Platform | Role | Documentation |
| :--- | :--- | :--- | :--- | :--- |
| `torii-chan` | Orange Pi Zero3 | aarch64-linux | WireGuard / DDNS | [README](hosts/torii-chan/README.md) |

## Key Technologies

- **Flakes:** For reproducible builds and dependency management.
- **sops-nix:** For encrypting secrets (passwords, API keys) via `age`.
- **Cross-Compilation:** Building aarch64 (ARM) images on x86_64 machines.

## Getting Started

To explore a specific host, navigate to its directory in `hosts/` and read the local README.
