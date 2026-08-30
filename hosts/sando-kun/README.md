# Host: sando-kun (i7-860 Tower Server)

This host is a general-purpose tower server equipped with an Intel Core i7-860 and an 80GB HDD configuration. It follows the standard configuration established by `shosoin-tan` and `kagutsuchi-sama`.

## Hardware Specifications
- **CPU:** Intel Core i7-860 (1st Generation)
- **GPU:** GeForce 8400 GS (Tesla)
- **RAM:** 8GB
- **Storage:**
  - 250GB HDD (OS / Boot)
  - 80GB HDD (`scratch`)

## Installation Guide

Since this host uses older hardware, we use the following high-reliability installation procedure (similar to `shosoin-tan`) to minimize CPU load and ensure compatibility.

### Phase 1: Prepare Disks
1. **Partition and mount** (layout defined in `hardware.nix`; verify device names with `lsblk`). Legacy BIOS (MBR):
   ```bash
   # 250GB HDD (system): part1 = swap, part2 = /boot (vfat), part3 = / (ext4)
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

   # 80GB HDD (scratch): /mnt/scratch (ext4)
   ssh nixos@<IP> "sudo parted /dev/sdb -- mklabel msdos && \
     sudo parted /dev/sdb -- mkpart primary ext4 1MiB 100% && \
     sudo mkfs.ext4 /dev/sdb1 && \
     sudo mkdir -p /mnt/scratch && \
     sudo mount /dev/sdb1 /mnt/scratch"
   ```

### Phase 2: Transfer Secret Key
`sops-nix` decrypts secrets during `nixos-install` (it runs the system activation),
so the age key must be in place **before** installing:
```bash
ssh nixos@<IP> "sudo mkdir -p /mnt/var/lib/sops-nix"
cat ~/.config/sops/age/keys.txt | ssh nixos@<IP> "sudo tee /mnt/var/lib/sops-nix/key.txt > /dev/null"
```

### Phase 3: Build and Transfer System (Recommended)
To reduce CPU load on the target, we transfer the pre-built image from the build host.
1. **Build:** `nix build .#nixosConfigurations.sando-kun.config.system.build.toplevel`
2. **Transfer:** `nix copy --to ssh://nixos@<IP> ./result`
3. **Install:** `ssh nixos@<IP> "sudo nixos-install --system $(readlink -f ./result)"`

## Network and Security
- **Boot Method:** Legacy BIOS (MBR)
- **Data Storage:** `/mnt/scratch` is mounted automatically.
- **Management IP:** `10.0.0.2` (Nebula mesh)
- **SSH Access Restriction:** For enhanced security, SSH access is limited to the Nebula (`nebula0`) mesh.

## Notes
- **GPU:** The GeForce 8400 GS is extremely old and modern NVIDIA drivers will not work. It runs on the open-source `nouveau` driver or standard kernel drivers.
