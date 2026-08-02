# Host: BrokenPC (Victus by HP 16-e1xxx)

NixOS desktop machine with a hybrid GPU configuration. This host is a "Victus by HP" gaming laptop used for daily work and development, managed via Nix Flakes.

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
3. **Run Disko:** 
   ```bash
   nix build .#nixosConfigurations.BrokenPC.config.system.build.diskoScript
   sudo ./result --mode zap_create_mount
   ```

### Phase 2: System Installation
```bash
sudo NIXPKGS_ALLOW_UNFREE=1 nixos-install --flake .#BrokenPC
```

### Phase 3: Transfer Secret Key (Important)
To ensure user passwords work on first boot, your age key needs to be at /mnt/var/lib/sops-nix/key.txt.
```bash
sudo mkdir -p /mnt/var/lib/sops-nix
# Copy your age key to /mnt/var/lib/sops-nix/key.txt
```
