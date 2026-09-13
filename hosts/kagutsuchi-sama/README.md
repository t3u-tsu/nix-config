# Host: kagutsuchi-sama (Xeon E5 Compute Server)

This host is a high-power tower server used for heavy workloads and compute tasks. It previously served as the Minecraft server and Update Producer, roles that have since been migrated to `shosoin-tan`.

## Hardware Specs
- **CPU:** Xeon E5-2650 v2 (8C/16T)
- **GPU:** GTX 980 Ti (Maxwell)
- **RAM:** 16GB
- **Storage:**
  - 500GB SSD (Root/Boot)
  - 3TB HDD (Data)

## Installation Guide

Run these commands from the NixOS Installer environment (via SSH).

1. **Partition and Mount Disks** (layout defined in `hardware.nix`; verify device names with `lsblk`):
   ```bash
   # 500GB SSD (system): /boot (vfat), / (ext4)
   ssh root@<ip> "parted /dev/sda -- mklabel gpt && \
     parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB && \
     parted /dev/sda -- set 1 esp on && \
     parted /dev/sda -- mkpart primary ext4 512MiB 100% && \
     mkfs.fat -F 32 /dev/sda1 && \
     mkfs.ext4 /dev/sda2 && \
     mount /dev/sda2 /mnt && \
     mkdir -p /mnt/boot && \
     mount /dev/sda1 /mnt/boot"

   # 3TB HDD (data): /mnt/data (ext4)
   ssh root@<ip> "parted /dev/sdb -- mklabel gpt && \
     parted /dev/sdb -- mkpart primary ext4 1MiB 100% && \
     mkfs.ext4 /dev/sdb1 && \
     mkdir -p /mnt/data && \
     mount /dev/sdb1 /mnt/data"
   ```

2. **Place SOPS Key:** (CRITICAL for password management)
   `sops-nix` decrypts secrets during `nixos-install`, so the identity at
   `/mnt/var/lib/sops-nix/key.txt` must decrypt `secrets/hosts/kagutsuchi-sama.yaml`
   (master + host key; the user key is excluded). Use the offline master age key,
   or the host key derived from the SSH host key registered in `.sops.yaml`
   (see [`hosts/README.md`](../README.md)):
   ```bash
   ssh root@<ip> "mkdir -p /mnt/var/lib/sops-nix"
   cat /path/to/master-age-key.txt | ssh root@<ip> "cat > /mnt/var/lib/sops-nix/key.txt"
   ```

3. **Install NixOS:**
   ```bash
   ssh root@<ip> "nixos-install --flake github:t3u-tsu/nix-config#kagutsuchi-sama"
   ```

4. **Reboot:**
   ```bash
   ssh root@<ip> "reboot"
   ```

## Access
- **Management IP:** `10.0.0.3` (Nebula mesh)
- **SSH Restriction:** SSH is restricted to the Nebula (`nebula0`) mesh ONLY.
- **User:** `t3u` (with wheel/sudo privileges)
- **Password:** Defined in `secrets/hosts/kagutsuchi-sama.yaml` (managed via sops-nix).
- **SSH Key:** Enabled for `t3u` and `root`.

## Known Issue: NAT Loopback
When this host is on the same LAN as the VPN server (`torii-chan`), the VPN can
fail because the router does not support NAT loopback for `torii-chan.t3u.uk`.

Set `my.networking.local-network.enable = true;` in
`hosts/kagutsuchi-sama/default.nix` (commented out by default). It resolves
`torii-chan.t3u.uk` to the local IP `192.168.0.128`.

**Important:** if this host moves outside the local VPN LAN, keep
`my.networking.local-network.enable = false;` (or commented out) so it resolves
the VPN server from the outside.
