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

- **torii-chan**: Orange Pi Zero3 (Allwinner H618)
  - Role: Gateway, WireGuard Server, DDNS
  - CPU: Allwinner H618, RAM: 1GB
  - Storage: 64GB microSD (Boot), 500GB HDD (Root)
- **shosoin-tan**: Tower Server
  - Role: Home Server, ZFS Storage
  - CPU: Core i7 870, GPU: Quadro K2200, RAM: 16GB
  - Storage: 480GB SSD (Root), 1TB x2 + 320GB x2 (ZFS Mirror), 2TB HDD (Backup)
- **kagutsuchi-sama**: High-power Tower Server
  - Role: Compute / Heavy Workloads
  - CPU: Xeon E5-2650 v2, GPU: GTX 980 Ti, RAM: 16GB
  - Storage: 500GB SSD (Root), 3TB + 160GB HDD

## Key Technologies

- **Flakes:** For reproducible builds and dependency management.
- **sops-nix:** For encrypting secrets (passwords, API keys) via `age`.
- **Cross-Compilation:** Building aarch64 (ARM) images on x86_64 machines.

## Deployment Guide

### For x86_64 hosts (kagutsuchi-sama, shosoin-tan)

If automatic deployment via `nixos-anywhere` fails, follow these manual steps from the installer environment:

1. **Partitioning with Disko:**
   Run this from the target machine (or via SSH):
   ```bash
   sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- \
     --mode destroy,format,mount \
     --flake github:t3u-tsu/nix-config#<hostname>
   ```

2. **Install NixOS:**
   ```bash
   sudo nixos-install --flake github:t3u-tsu/nix-config#<hostname>
   ```

3. **Reboot:**
   ```bash
   sudo reboot
   ```

### For torii-chan (SD to HDD)

1. **Rsync data to HDD:** (Assuming HDD is mounted at `/mnt`)
   ```bash
   rsync -avxHAX --progress / /mnt/
   ```
2. **Switch config:**
   ```bash
   nix run nixpkgs#nixos-rebuild -- switch --flake .#torii-chan --target-host root@<ip>
   ```
