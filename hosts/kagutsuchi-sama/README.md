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
   ssh -t root@<ip> "nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- \
     --mode destroy,format,mount \
     --flake github:t3u-tsu/nix-config#kagutsuchi-sama"
   ```

2. **Place SOPS Key:** (CRITICAL for password management)
   ```bash
   ssh root@<ip> "mkdir -p /mnt/var/lib/sops-nix"
   cat ~/.config/sops/age/keys.txt | ssh root@<ip> "cat > /mnt/var/lib/sops-nix/key.txt"
   ```

3. **Install NixOS:**
   ```bash
   ssh root@<ip> "nixos-install --flake github:t3u-tsu/nix-config#kagutsuchi-sama"
   ```

4. **Reboot:**
   ```bash
   ssh root@<ip> "reboot"
   ```

## 🔐 Access
- **User:** `t3u` (with wheel/sudo privileges)
- **Password:** Defined in `secrets.yaml` (managed via sops-nix).
- **SSH Key:** Enabled for `t3u` and `root`.

