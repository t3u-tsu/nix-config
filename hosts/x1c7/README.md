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

`hardware.nix` is generated on the machine with
`nixos-generate-config --root /mnt --dir /tmp/nixos`; copy its
`fileSystems` / `swapDevices` into `hosts/x1c7/hardware.nix`.

Boot the NixOS live USB, partition (GPT: ESP + root), mount, then:

```bash
sudo NIXPKGS_ALLOW_UNFREE=1 nixos-install --flake .#x1c7
```

Before install, register the host's SSH-derived age key in SOPS (see
`hosts/README.md`). The age secret must be reachable at install time, so derive
it from the SSH host key the installed system will reuse.

See `hosts/README.md` for the full add-a-host workflow (SOPS / Nebula).

## Reference

- [Lenovo ThinkPad X1 Carbon (Gen 7) — Arch Wiki](https://wiki.archlinux.jp/index.php/Lenovo_ThinkPad_X1_Carbon_(Gen_7))
- [NixOS Hardware: lenovo/thinkpad/x1/7th-gen](https://github.com/NixOS/nixos-hardware/blob/master/lenovo/thinkpad/x1/7th-gen/default.nix)
- [NixOS Wiki: Laptop](https://wiki.nixos.org/wiki/Laptop)
