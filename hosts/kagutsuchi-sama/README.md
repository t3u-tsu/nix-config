# Host: kagutsuchi-sama (Xeon E5 Compute Server)

This host is a high-power tower server used for heavy workloads and compute tasks.

## Hardware Specs
- **CPU:** Xeon E5-2650 v2 (8C/16T)
- **GPU:** GTX 980 Ti (Maxwell)
- **RAM:** 16GB
- **Storage:**
  - 500GB SSD (Root/Boot)
  - 3TB HDD (Data)
  - 160GB HDD (Scratch)

## 🚀 Installation Guide

Run these commands from the NixOS Installer environment:

1. **Format and Mount Disks:**
   ```bash
   sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- \
     --mode destroy,format,mount \
     --flake github:t3u-tsu/nix-config#kagutsuchi-sama
   ```

2. **Install NixOS:**
   ```bash
   sudo nixos-install --flake github:t3u-tsu/nix-config#kagutsuchi-sama
   ```

3. **Set Password for t3u:**
   After rebooting, the user `t3u` will be available with the SSH key defined in `configuration.nix`.

