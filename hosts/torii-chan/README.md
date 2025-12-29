# Host: torii-chan (Orange Pi Zero3)

This directory contains the NixOS configuration for `torii-chan`, an Orange Pi Zero3 node used as a WireGuard server and DDNS client.

## Hardware Specs
- **Model:** Orange Pi Zero3 (Allwinner H618)
- **Architecture:** aarch64-linux

## Configurations in Flake
- `torii-chan-sd`: Initial SD card image build.
- `torii-chan-sd-live`: Update system while running on SD card.
- `torii-chan`: Production configuration with root on HDD.

---

## 🚀 Setup Guide

### Phase 1: Build & Flash SD Image
1. **Build the SD Image:**
   ```bash
   nix build .#nixosConfigurations.torii-chan-sd.config.system.build.sdImage
   ```
2. **Flash to SD Card:**
   ```bash
   sudo dd if=result/sd-image/nixos-image-sd-card-*.img of=/dev/sdX bs=4M status=progress conv=fsync
   ```

### Phase 2: Initial Provisioning
1. **Insert Key:** Place your age secret key at `/var/lib/sops-nix/key.txt`.
2. **First Deploy:**
   ```bash
   nix run nixpkgs#nixos-rebuild -- switch --flake .#torii-chan-sd-live --target-host root@192.168.0.128
   ```

### Phase 3: Migrate to HDD (Optional)
1. **Prepare HDD:** Format with label `NIXOS_HDD`.
2. **Copy Data:** Rsync `/` to the HDD partition.
3. **Switch Config:**
   ```bash
   nix run nixpkgs#nixos-rebuild -- switch --flake .#torii-chan --target-host t3u@10.0.0.1 --use-remote-sudo
   ```

## 🔐 Services & Secrets
- **WireGuard:** VPN server on port 51820.
- **DDNS:** Cloudflare DDNS (favonia). Requires API Token.
- **Secrets:** Managed via `sops-nix`. Edit with `sops secrets/secrets.yaml`.
