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

- **torii-chan**: Orange Pi Zero3 (Allwinner H618).
  - Role: Gateway, WireGuard Server, DDNS.
  - Storage: SD (Root) + HDD (Data/Work).
- **shosoin-tan**: Tower Server (Core i7 870, Quadro K2200).
  - Role: Home Server, ZFS Storage.
  - Storage: SSD (Root) + ZFS Mirror (1TB x2, 320GB x2) + HDD (2TB Backup).

## Key Technologies

- **Flakes:** For reproducible builds and dependency management.
- **sops-nix:** For encrypting secrets (passwords, API keys) via `age`.
- **Cross-Compilation:** Building aarch64 (ARM) images on x86_64 machines.

## Getting Started

To explore a specific host, navigate to its directory in `hosts/` and read the local README.
