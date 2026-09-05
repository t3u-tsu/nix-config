# Host: BrokenPC (Victus by HP 16-e1xxx)

NixOS gaming laptop with a hybrid GPU configuration. This host is a "Victus by HP" laptop used for daily work and development, managed via Nix Flakes.

## Hardware Specs
- **CPU**: AMD Ryzen 7 6800H (16 threads)
- **GPU**: 
  - NVIDIA GeForce RTX 3050 Ti Mobile (Discrete)
  - AMD Radeon 680M (Integrated)
- **RAM**: 16GB DDR5
- **Storage**:
  - 512GB NVMe SSD (`nvme-MTFDKBA512TFH-1BC1AABHA_UMDMC01ZRH9LRX`) for OS/Boot
  - 1TB NVMe SSD (`nvme-FIKWOT_FN500_1TB_AA000000000000000188`) mapped to `/data`

## GPU Configuration (Battery-first: PRIME offload)

- The AMD Radeon 680M iGPU is the primary renderer (set via `WLR_DRM_DEVICES` on the niri user service, using PCI by-path so it stays stable across boots).
- The NVIDIA RTX 3050 Ti runs the **open kernel modules** (`nvidia_cachyos.open`, driver 610.x) with **RTD3 power management** (`finegrained`): it powers down when idle and is only activated on demand.
- Launch games on the dGPU with `nvidia-offload` (Steam desktop entry "Steam (NVIDIA)" or the `steam-nvidia` alias). For per-game offloading, set the Steam launch option to `nvidia-offload %command%` (optionally wrapped in `gamescope -e --`).
- Lid behavior: suspend on battery, lock on AC, ignore when docked (`services.logind.settings.Login`).

## Installation Guide (Clean Install)

### Phase 1: Disk Preparation
1. **Boot from NixOS Installer USB.**
2. **Setup Network:** Connect to Wi-Fi/Ethernet.
3. **Partition the disks** (layout defined in `hardware.nix`; verify device names with `lsblk`):
   ```bash
   # 512GB NVMe (system): /boot (vfat), swap, / (ext4)
   sudo parted /dev/nvme0n1 -- mklabel gpt
   sudo parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
   sudo parted /dev/nvme0n1 -- set 1 esp on
   sudo parted /dev/nvme0n1 -- mkpart primary linux-swap 512MiB 8GiB
   sudo parted /dev/nvme0n1 -- mkpart primary ext4 8GiB 100%
   sudo mkfs.fat -F 32 /dev/nvme0n1p1
   sudo mkswap /dev/nvme0n1p2
   sudo mkfs.ext4 /dev/nvme0n1p3

   # 1TB NVMe (data): /data (ext4)
   sudo parted /dev/nvme1n1 -- mklabel gpt
   sudo parted /dev/nvme1n1 -- mkpart primary ext4 1MiB 100%
   sudo mkfs.ext4 /dev/nvme1n1p1
   ```
4. **Mount the partitions:**
   ```bash
   sudo mount /dev/nvme0n1p3 /mnt
   sudo mkdir -p /mnt/boot /mnt/data
   sudo mount /dev/nvme0n1p1 /mnt/boot
   sudo swapon /dev/nvme0n1p2
   sudo mount /dev/nvme1n1p1 /mnt/data
   ```

### Phase 2: Transfer Secret Key (Important)
`sops-nix` decrypts secrets during `nixos-install` (it runs the system activation),
so the age key must be in place **before** installing:
```bash
sudo mkdir -p /mnt/var/lib/sops-nix
# Copy your age key to /mnt/var/lib/sops-nix/key.txt
```

### Phase 3: System Installation
```bash
sudo NIXPKGS_ALLOW_UNFREE=1 nixos-install --flake .#BrokenPC
```
