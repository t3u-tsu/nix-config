# Host: shosoin-tan (i7-870 Tower Server)

This host is a tower server equipped with an Intel Core i7-870 and a ZFS Mirror configuration, currently serving as the Minecraft server and a general-purpose home server.

## Hardware Specs
- **CPU:** Intel Core i7-870 (1st Gen)
- **GPU:** Quadro K2200 (Maxwell)
- **RAM:** 16GB
- **Storage:**
  - 480GB SSD (OS / Boot)
  - 1TB HDD x2 (ZFS Mirror: `tank-1tb`)
  - 320GB HDD (ext4, mounted to `/mnt/data-320gb`)

## Installation Guide

Due to older hardware and high build loads, this host uses a specific remote-build installation procedure for stability.

### Phase 1: Disk Preparation
1. **Partition and mount** (layout defined in `hardware.nix`; verify device names with `lsblk`). Legacy BIOS (MBR):
   ```bash
   # 480GB SSD (system): part1 = swap, part2 = /boot (vfat), part3 = / (ext4)
   ssh nixos@<IP> "sudo parted /dev/sda -- mklabel msdos && \
     sudo parted /dev/sda -- mkpart primary linux-swap 1MiB 8GiB && \
     sudo parted /dev/sda -- mkpart primary fat32 8GiB 8.5GiB && \
     sudo parted /dev/sda -- set 2 boot on && \
     sudo parted /dev/sda -- mkpart primary ext4 8.5GiB 100% && \
     sudo mkswap /dev/sda1 && sudo swapon /dev/sda1 && \
     sudo mkfs.fat -F 32 /dev/sda2 && \
     sudo mkfs.ext4 /dev/sda3 && \
     sudo mount /dev/sda3 /mnt && \
     sudo mkdir -p /mnt/boot && \
     sudo mount /dev/sda2 /mnt/boot"
   ```
2. **Create the ZFS mirror pool** (`tank-1tb`, 2x 1TB HDD — **destructive**, wipes both disks):
   ```bash
   ssh nixos@<IP> "sudo modprobe zfs && \
     sudo zpool create tank-1tb mirror /dev/sdb /dev/sdc"
   ```
3. **Mount the 320GB HDD** (`/mnt/data-320gb`):
   ```bash
   ssh nixos@<IP> "sudo parted /dev/sdd -- mklabel msdos && \
     sudo parted /dev/sdd -- mkpart primary ext4 1MiB 100% && \
     sudo mkfs.ext4 /dev/sdd1 && \
     sudo mkdir -p /mnt/data-320gb && \
     sudo mount /dev/sdd1 /mnt/data-320gb"
   ```

### Phase 2: Transfer Secret Key
`sops-nix` decrypts secrets during `nixos-install` (it runs the system activation),
so the age key must be in place **before** installing:
```bash
ssh nixos@<IP> "sudo mkdir -p /mnt/var/lib/sops-nix"
cat ~/.config/sops/age/keys.txt | ssh nixos@<IP> "sudo tee /mnt/var/lib/sops-nix/key.txt > /dev/null"
```

### Phase 3: Build and Transfer System (Recommended)
To avoid CPU freezes on the target, build the image on a build host and transfer it.
1. **Build:** `nix build .#nixosConfigurations.shosoin-tan.config.system.build.toplevel`
2. **Transfer:** `nix copy --to ssh://nixos@<IP> ./result`
3. **Install:** `ssh nixos@<IP> "sudo nixos-install --system $(readlink -f ./result)"`

## Network and Security
- **Boot Method:** Legacy BIOS (MBR)
- **Automated Update:** Configuration locking and plugins are automatically updated daily at 04:00 JST via GitHub Actions, which commits changes back to the repository.
- **Minecraft Data:** Located at `/srv/minecraft`.
- **Minecraft Discord Bridge:** Discord management bot is active. Socket at `/run/minecraft-discord-bridge/bridge.sock`.
- **Backup:** Runs every 2 hours via `restic`.
  - Dual setup: Local (`/mnt/tank-1tb/backups/minecraft`) and Remote (`kagutsuchi-sama`).
- **Management IP:** `10.0.0.4` (Nebula mesh)
- **MTU Setting:** Nebula MTU is set to `1320` (common across the fleet).
- **SSH Access Control:** Limited to the Nebula (`nebula0`) mesh ONLY for enhanced security.

## Notes
- **Overclocking:** CPU overclocking can cause instability (Kernel Oops) during heavy Nix builds. Running at stock speeds is highly recommended.
- **resolv.conf:** If networking services fail due to signature mismatch after installation, manually delete `/etc/resolv.conf` and restart.
