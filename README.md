# My NixOS Fleet

This repository manages multiple NixOS configurations using Flakes. It is designed for cross-compilation and secure secret management.

## Directory Structure

```text
.
├── flake.nix           # Entry point for the configuration
├── hosts/              # Host-specific configurations
│   └── torii-chan/     # Orange Pi Zero3 configuration
├── common/             # Shared configurations across all hosts
├── services/           # Common service configurations (Minecraft, etc.)
│   └── minecraft/
│       └── plugins/    # Plugin management via nvfetcher
├── lib/                # Common library functions for mkSystem
├── secrets/            # Encrypted secrets (SOPS)
    └── secrets.yaml
```

## Hosts

| Host | Mgmt IP (WG0) | App IP (WG1) | Role | Hardware | Storage |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `torii-chan` | `10.0.0.1` | `10.0.1.1` | Gateway / DDNS (`mc.t3u.uk`) | Orange Pi Zero3 (H618 / 1GB) | 64GB SD / 500GB HDD |
| `sando-kun` | `10.0.0.2` | `10.0.1.2` | Sando Server | i7 860 / 8GB | 250GB HDD / ZFS Mirror |
| `kagutsuchi-sama` | `10.0.0.3` | `10.0.1.3` | Compute / Minecraft Server | Xeon E5-2650 v2 / 16GB / GTX 980 Ti | 500GB SSD / 3TB HDD |
| `shosoin-tan` | `10.0.0.4` | `10.0.1.4` | ZFS / Home Server | i7 870 / 16GB / K2200 | 480GB SSD / ZFS Mirror |
| **Management PC** | `10.0.0.100` | - | Admin / Client | - | - |

## Security

- **Management Network (wg0):** Private 10.0.0.0/24 network. SSH access is restricted to this interface.
- **Application Network (wg1):** Private 10.0.1.0/24 network for inter-server communication (proxies, etc.).
- **SOPS:** Secrets are managed via `sops-nix` and `age`.

## Technologies

- **Flakes:** For reproducible builds and dependency management.
- **sops-nix:** For encrypting secrets (passwords, API keys) via `age`.
- **nvfetcher:** For managing external binary assets (like Minecraft plugins) with automatic version tracking and hash calculation.
- **Cross-Compilation:** Building aarch64 (ARM) images on x86_64 machines.

## Deployment Guide

### For x86_64 hosts (kagutsuchi-sama, shosoin-tan)

To deploy to a new machine using the NixOS Live USB:

1. **Boot the target machine from the Live USB.**
2. **Setup SSH on the target:** (if not already accessible)
   ```bash
   sudo passwd root # Set a temporary password
   ```
3. **Partitioning with Disko (from local machine):**
   ```bash
   ssh -t root@<target-ip> "nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- \
     --mode destroy,format,mount \
     --flake github:t3u-tsu/nix-config#<hostname>"
   ```
4. **Install NixOS (from local machine):**
   ```bash
   ssh root@<target-ip> "nixos-install --flake github:t3u-tsu/nix-config#<hostname>"
   ```
5. **Reboot:**
   ```bash
   ssh root@<target-ip> "reboot"
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
