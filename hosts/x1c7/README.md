# Host: x1c7 (ThinkPad X1 Carbon Gen 7)

NixOS desktop laptop (Lenovo ThinkPad X1 Carbon Gen 7, model **20QES11500**),
managed via Nix Flakes. This is the primary mobile/development machine.

## Hardware Specs
- **CPU**: Intel Core (Whiskey Lake, 8th gen — i5-8265U / i7-8565U depending on the config)
- **GPU**: Intel UHD Graphics 620 (integrated)
- **RAM**: 16GB LPDDR3 (soldered)
- **Storage**: NVMe SSD (M.2 2280)
  - `__REPLACE_ESP__` — ESP (vfat, `/boot`)
  - `__REPLACE_ROOT__` — root (ext4, `/`)
  - Swap via zram (no swap partition)
- **Display**: 14" (eDP-1)
- **WiFi / BT**: Intel Wireless-AC 9560 + Bluetooth

## Hardware note
The by-id device paths in `hardware.nix` are placeholders. Before installing,
confirm them on the real machine:
```bash
lsblk -o NAME,PATH,UUID
```
and replace `__REPLACE_ESP__` / `__REPLACE_ROOT__` with the actual by-id names
(as done in the other hosts, e.g. `hosts/sando-kun/hardware.nix`).

## Role / Services
- NixOS desktop (desktop profile, full stack)
- Nebula mesh member
  - IP: `10.0.0.5` (group: `mgmt`)
- sshd (key-based) for remote administration over the mesh
- Intel GPU: `throttled` power management (from nixos-hardware x1-7th-gen)

## Deployment (existing NixOS)
```bash
sudo nixos-rebuild switch --flake .#x1c7
```

Over the Nebula mesh (from another host):
```bash
nixos-rebuild switch --flake .#x1c7 --target-host t3u@10.0.0.5 --sudo --ask-sudo-password
```

## Installation (clean install)
1. Boot the NixOS installer, partition disks per `hardware.nix`:
   ```bash
   sudo parted /dev/nvme0n1 -- mklabel gpt
   sudo parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
   sudo parted /dev/nvme0n1 -- set 1 esp on
   sudo parted /dev/nvme0n1 -- mkpart primary ext4 512MiB 100%
   sudo mkfs.fat -F 32 /dev/nvme0n1p1
   sudo mkfs.ext4 /dev/nvme0n1p2
   ```
2. Mount and copy the SOPS age key:
   ```bash
   sudo mount /dev/nvme0n1p2 /mnt
   sudo mkdir -p /mnt/boot /mnt/var/lib/sops-nix
   sudo mount /dev/nvme0n1p1 /mnt/boot
   # copy the age key (derived from the SSH host key) to /mnt/var/lib/sops-nix/key.txt
   ```
3. Register the host key in `.sops.yaml` (see `hosts/README.md`) before install.
4. Install:
   ```bash
   sudo NIXPKGS_ALLOW_UNFREE=1 nixos-install --flake .#x1c7
   ```

See `hosts/README.md` for the full add-a-host workflow (SOPS / Nebula).
