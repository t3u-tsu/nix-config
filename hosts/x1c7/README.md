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
  - IP: `10.0.0.101` (group: `mgmt`)
- sshd (key-based) for remote administration over the mesh
- Intel GPU: `throttled` power management (from nixos-hardware x1-7th-gen)

## Deployment (existing NixOS)
```bash
sudo nixos-rebuild switch --flake .#x1c7
```

Over the Nebula mesh (from another host):
```bash
nixos-rebuild switch --flake .#x1c7 --target-host t3u@10.0.0.101 --sudo --ask-sudo-password
```

## Installation (clean install)

The layout below assumes a single NVMe SSD. Confirm the actual by-id names on
the live USB with `lsblk -o NAME,PATH,UUID` and update `hardware.nix` before
building.

### Phase 1 — Live USB & disk prep
1. Boot the NixOS live USB and connect to Wi-Fi/eEthernet.
2. Partition (this erases all existing data):
   ```bash
   sudo parted /dev/nvme0n1 -- mklabel gpt
   sudo parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
   sudo parted /dev/nvme0n1 -- set 1 esp on
   sudo parted /dev/nvme0n1 -- mkpart primary ext4 512MiB 100%
   sudo mkfs.fat -F 32 /dev/nvme0n1p1
   sudo mkfs.ext4 /dev/nvme0n1p2
   ```
3. Mount:
   ```bash
   sudo mount /dev/nvme0n1p2 /mnt
   sudo mkdir -p /mnt/boot /mnt/var/lib/sops-nix
   sudo mount /dev/nvme0n1p1 /mnt/boot
   ```

### Phase 2 — SSH host key & SOPS age key (BEFORE install)
`sops-nix` decrypts during `nixos-install`, so the age identity must be in place
first. Because the age key is derived from the **SSH host key**, pre-generate
that key so the installed system reuses it, then register its age public key:
   ```bash
   # generate the SSH host key the installed system will reuse
   sudo mkdir -p /mnt/etc/ssh
   sudo ssh-keygen -t ed25519 -N "" -f /mnt/etc/ssh/ssh_host_ed25519_key

   # the age public key to register in `.sops.yaml` (give it to the operator):
   ssh-to-age -i /mnt/etc/ssh/ssh_host_ed25519_key.pub

   # derive the private age key that sops-nix will read on the installed host
   ssh-to-age -private-key -i /mnt/etc/ssh/ssh_host_ed25519_key \
     | sudo tee /mnt/var/lib/sops-nix/key.txt >/dev/null
   sudo chmod 600 /mnt/var/lib/sops-nix/key.txt
   ```
(If `ssh-to-age` is unavailable on the live USB, `nix run nixpkgs#ssh-to-age`.)

### Phase 3 — Install
```bash
sudo NIXPKGS_ALLOW_UNFREE=1 nixos-install --flake .#x1c7
```

This host uses GRUB with EFI support; the ESP mounted at `/mnt/boot` (and
`boot.loader.efi.canTouchEfiVariables`) makes it the boot entry. After the first
boot, SSH in (or use the console) and rebuild via
[`nixos-rebuild switch --flake .#x1c7`](#deployment-existing-nixos).

See `hosts/README.md` for the full add-a-host workflow (SOPS / Nebula).
