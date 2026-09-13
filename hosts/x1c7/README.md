# Host: x1c7 (ThinkPad X1 Carbon Gen 7)

Lenovo ThinkPad X1 Carbon Gen 7 (20QES11500) running NixOS, managed via Nix
Flakes.

## Hardware

- **CPU**: Intel Core Whiskey Lake (8th gen), iGPU **Intel UHD Graphics 620**
- **RAM**: 16GB (soldered)
- **Storage**: M.2 NVMe SSD (e.g. WD Black SN720)
- **Display**: 14" (eDP-1)
- **WiFi / BT**: Intel Wireless-AC 9560 (CNVi, `iwlwifi`) + Bluetooth
- **Thunderbolt 3**: Intel JHL6540 (Alpine Ridge)
- **Audio**: Intel HDA, 4 speakers
- **Input**: Synaptics touchpad / fingerprint (`06cb:00bd`)

## Firmware / BIOS notes (Arch wiki)

- `Config -> Power -> Sleep State` → **Linux** (S3).
- `Config -> Thunderbolt BIOS Assist Mode` → **Enabled** (avoids higher CPU wake
  power draw on s2idle).
- Suspend can wake immediately if a Bluetooth device is connected — disconnect
  BT before suspending.
- The EC/BIOS can be updated via `fwupd` (LVFS) to address the 80°C thermal
  throttle.

## Configuration

- desktop profile (lightweight core)
- nixos-hardware `lenovo-thinkpad-x1-7th-gen`: trackpoint, Intel CPU/GPU,
  `common/pc/laptop` + `ssd`, and `services.throttled`
- `services.tlp.enable = true`
- Nebula mesh member: `10.0.0.101` (groups `mgmt`, `app`)

> TLP ignores the Synaptics touchpad by default, so it is not excluded from
> USB autosuspend and can stop working after resume. Add it to
> `services.tlp.settings.USB_BLACKLIST` (`06cb:00bd`) if needed (Arch wiki).

## Deployment

```bash
sudo nixos-rebuild switch --flake .#x1c7
```

## Installation (clean install)

This host is installed from the live USB. The steps below are the ones used to
install x1c7.

### 0. Boot & connect
Boot the NixOS installer and connect to a network (Wi-Fi):
```bash
nmcli device wifi connect "<SSID>" password "<pass>"
```

### 1. Identify the disk
```bash
lsblk -o NAME,SIZE,PATH,TRAN
```
Expect a single NVMe device (`/dev/nvme0n1`).

### 2. Fetch the repo
```bash
git clone -b feat/add-x1c7 https://github.com/t3u-tsu/nix-config.git /tmp/nix-config
cd /tmp/nix-config
```

### 3. Pre-generate the SSH host key (SOPS age identity)
The SOPS age identity is derived from the SSH host key, so generate it and print
the age public key to register in `.sops.yaml`:
```bash
sudo mkdir -p /mnt/etc/ssh /mnt/var/lib/sops-nix
sudo ssh-keygen -t ed25519 -N "" -f /mnt/etc/ssh/ssh_host_ed25519_key
nix-shell -p ssh-to-age --command 'ssh-to-age -i /mnt/etc/ssh/ssh_host_ed25519_key.pub'
```

### 4. Partition & mount
```bash
sudo parted /dev/nvme0n1 -- mklabel gpt
sudo parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 2GiB
sudo parted /dev/nvme0n1 -- set 1 esp on
sudo parted /dev/nvme0n1 -- mkpart primary ext4 2GiB 100%
sudo mkfs.fat -F 32 /dev/nvme0n1p1
sudo mkfs.ext4 /dev/nvme0n1p2
sudo mount /dev/nvme0n1p2 /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/nvme0n1p1 /mnt/boot
```

### 5. Put the age secret in place
The SSH host key was generated with `sudo`, so read it as root:
```bash
sudo nix-shell -p ssh-to-age --command 'ssh-to-age -private-key -i /mnt/etc/ssh/ssh_host_ed25519_key' \
  | sudo tee /mnt/var/lib/sops-nix/key.txt >/dev/null
sudo chmod 600 /mnt/var/lib/sops-nix/key.txt
```

### 6. Hardware config & install
Generate the hardware config on the machine; note it writes
`hardware-configuration.nix`, not `hardware.nix`:
```bash
nixos-generate-config --root /mnt --dir /tmp/nixos
cat /tmp/nixos/hardware-configuration.nix
```
Copy its `fileSystems` / `swapDevices` / kernel-module lines into
`hosts/x1c7/hardware.nix`, then install:
```bash
sudo NIXPKGS_ALLOW_UNFREE=1 nixos-install --flake .#x1c7
```

Register the host's SSH-derived age key in SOPS **before** install (see
`hosts/README.md`); the age secret placed at `/mnt/var/lib/sops-nix/key.txt` must
match the identity used to encrypt `secrets/hosts/x1c7.yaml`.

See `hosts/README.md` for the full add-a-host workflow (SOPS / Nebula).

## Reference

- [Lenovo ThinkPad X1 Carbon (Gen 7) — Arch Wiki](https://wiki.archlinux.jp/index.php/Lenovo_ThinkPad_X1_Carbon_(Gen_7))
- [NixOS Hardware: lenovo/thinkpad/x1/7th-gen](https://github.com/NixOS/nixos-hardware/blob/master/lenovo/thinkpad/x1/7th-gen/default.nix)
- [NixOS Wiki: Laptop](https://wiki.nixos.org/wiki/Laptop)
