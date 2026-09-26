# Host: x1c7 (ThinkPad X1 Carbon Gen 7)

Lenovo ThinkPad X1 Carbon Gen 7 (20QES11500) running NixOS, managed via Nix
Flakes.

## Hardware

- **CPU**: Intel Core i7-8565U (Whiskey Lake-U, 4c/8t), iGPU **Intel UHD Graphics 620**
- **RAM**: 16 GB (soldered)
- **Storage**: Samsung PM981 256 GB NVMe (`MZVLB256HBHQ-000L7`)
- **Display**: 14" BOE NE140FHM-N61 (eDP-1)
- **WiFi / BT**: Intel Wireless-AC 9560 (CNVi, `8086:9df0`, `iwlwifi`) and Bluetooth (`8087:0aaa`)
- **Thunderbolt 3**: Intel JHL6540 (Alpine Ridge), kernel-managed
- **Audio**: Intel HDA with Sound Open Firmware
- **Input**: Synaptics I2C touchpad and TrackPoint (`SYNA8004:00 06CB:CD8B`)
- **Fingerprint**: Synaptics Prometheus (`06cb:00bd`)
- **Camera**: Chicony (`04f2:b67d`); this unit has no IR camera
- **TPM**: STMicroelectronics TPM 2.0

## Firmware / BIOS notes

- `Config -> Power -> Sleep State` is set to **Linux** (S3). libfprint upstream
  and a Lenovo engineer both favour s2idle instead, so switching is a trade of
  suspend power draw against fingerprint reliability after resume.
- `Config -> Thunderbolt BIOS Assist Mode`: the kernel drives the controller
  natively here (`/sys/bus/thunderbolt/devices/domain0` exists, security level
  `none`). Enabling BIOS Assist Mode hands it back to firmware and loses that
  native management, so it stays as is.
- Suspend can wake immediately while a Bluetooth device is connected; disconnect
  such peripherals first.
- Firmware is current as of 2026-09 (BIOS `N2HET85W` 1.68, EC 0.1.27, ME
  192.95.2489, Thunderbolt NVM 47.00); `fwupdmgr get-updates` reports nothing.
  The fingerprint reader does not appear in `fwupdmgr get-devices` even though
  fprintd sees it.
- The Arch Wiki warns that enrolling custom Secure Boot keys is reported to
  brick this model.

## Power and thermal management

Configuration lives in [`services/power.nix`](services/power.nix).

### TLP

nixos-hardware's `common/pc/laptop` enables `services.tlp` and, in doing so,
excludes power-profiles-daemon and tuned.

- **Charge thresholds 75/80.** The battery showed 429 cycles with no measurable
  capacity loss when this was measured, so this trades roughly 20% of runtime
  for slower wear rather than fixing an existing problem. `sudo tlp fullcharge`
  lifts the limit to 100% until the charger is unplugged.
- **`services.tlp.pd`** exposes the `net.hadess.PowerProfiles` D-Bus interface.
  Noctalia's `power_profile` bar widget reads that interface and silently does
  nothing without a provider. nixpkgs asserts that `tlp.pd` and
  power-profiles-daemon cannot coexist, and upstream recommends TLP.

### throttled

nixos-hardware enables `services.throttled` but leaves upstream's project
defaults: AC PL1/PL2 of 44 W and a 95 C trip. The throttled README describes
those as "not recommendations for every system".

The i7-8565U is rated 15 W base and 25 W configurable TDP-up, and this chassis
has one fan. At 44 W the CPU reaches the trip temperature and loses frequency
anyway, so the limits are resized to 25 W PL1 / 35 W PL2 on AC and 15 W / 25 W
on battery, with trip temperatures of 90 C and 85 C. `Disable_BDPROCHOT` stays
`False` so the embedded controller keeps its own 80 C throttle.

Idle with these limits measures around 66-70 C package temperature and a
4700 RPM fan.

## Memory and swap

NixOS default reclaim timings, combined with up to 8 parallel Nix builds, drove
this 16 GB machine into OOM kills of `rustc`, `nix`, `cudafe++` and `zig`, with
single processes reaching ~10 GB of anonymous memory.

- **zram**: `memoryPercent = 100`, which caps uncompressed data rather than the
  memory actually consumed, and `priority = 100`. The high priority keeps zram
  as the first swap in normal use, while systemd skips zram devices when
  choosing a hibernation target.
- **Swapfile**: 16 GiB at `/var/lib/swapfile`, matching RAM so that a
  hibernation image fits.
- **sysctls**: `vm.swappiness = 180`, `vm.watermark_boost_factor = 0`,
  `vm.watermark_scale_factor = 125` and `vm.page-cluster = 0`, taken from the
  Arch Wiki's zram tuning. The NixOS defaults, `watermark_scale_factor = 10` in
  particular, begin reclaiming far too late.
- Hibernation is staged but not yet verified; see
  [`services/power.nix`](services/power.nix) and [`hardware.nix`](hardware.nix).

## Fingerprint

The reader needs no configuration; only a fingerprint has to be enrolled.
libfprint lists `06cb:00bd` under its synaptics driver, and fprintd already
exposes the device on D-Bus.

### Enrolling

`services.fprintd.enable = true` places the CLI in `environment.systemPackages`.
Enrolment asks polkit for authorisation, so an authentication agent must be
running; Noctalia starts `polkit-kde-agent`.

```bash
fprintd-enroll                        # right index finger of the current user
fprintd-enroll -f left-index-finger   # any specific finger
fprintd-verify                        # confirm a print reads back
fprintd-list "$USER"                  # list enrolled fingers
fprintd-delete "$USER"                # start over
```

The sensor is touch-based: **press and lift five times** rather than swiping.
Should verification keep failing, vary how long the finger is held down.

### PAM integration

nixpkgs defaults `security.pam.services.<name>.fprintAuth` to
`config.services.fprintd.enable`, so enabling fprintd inserts `pam_fprintd.so`
as `sufficient` into 22 PAM services, including `sudo`, `su`, `polkit-1`,
`greetd`, `swaylock` and `login`. Fingerprint authentication therefore covers
login, the lock screen, `sudo` and polkit without further configuration.

The module is `sufficient` and ordered first, so a failed scan falls through to
the password prompt. Keep that fallback: making it `required` would lock you out
if the reader ever fails.

To narrow the scope, disable it per service:

```nix
security.pam.services.polkit-1.fprintAuth = false;
```

CVE-2024-37408 is why the Arch Wiki warns against fingerprint-only
authentication for `su`, `polkit` and `sudo`: a background process can trigger
an authentication the user did not intend. The CVE covers fprintd through
1.94.3, and this host runs 1.94.5, which carries the fix.

### After resume

If the reader stops working after suspend, the Arch Wiki documents three
countermeasures:

- fprintd can start before the USB device is re-initialised; a udev rule setting
  `power/persist = 1` for `06cb:00bd` addresses that.
- fprintd survives a successful login for 30 seconds, and sleeping within that
  window can break it; a unit running `killall fprintd` before `sleep.target`
  covers that case.
- libfprint upstream recommends s2idle over S3 for suspend, while the BIOS here
  is set to S3.

## Configuration

- desktop profile (lightweight core)
- nixos-hardware `lenovo-thinkpad-x1-7th-gen`: trackpoint, Intel CPU/GPU
  (microcode, VA-API, compute runtime), `common/pc/laptop` and `ssd`, plus
  `services.throttled`
- Nebula mesh member: `10.0.0.101` (groups `mgmt`, `app`)
- TPM 2.0 enabled ahead of a possible LUKS migration; unused so far

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
git clone https://github.com/t3u-tsu/nix-config.git /tmp/nix-config
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

The identity at `/mnt/var/lib/sops-nix/key.txt` must match the key used to
encrypt `secrets/hosts/x1c7.yaml`, and its public key has to be registered in
SOPS before the install (see [`hosts/README.md`](../README.md)) - otherwise activation fails.

## Reference

- [Lenovo ThinkPad X1 Carbon (Gen 7) — Arch Wiki](https://wiki.archlinux.org/title/Lenovo_ThinkPad_X1_Carbon_(Gen_7))
- [fprint — Arch Wiki](https://wiki.archlinux.org/title/Fprint)
- [TLP — Arch Wiki](https://wiki.archlinux.org/title/TLP)
- [Zram — Arch Wiki](https://wiki.archlinux.org/title/Zram)
- [Power management/Suspend and hibernate — Arch Wiki](https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate)
- [Intel graphics — Arch Wiki](https://wiki.archlinux.org/title/Intel_graphics)
- [NixOS Hardware: lenovo/thinkpad/x1/7th-gen](https://github.com/NixOS/nixos-hardware/blob/master/lenovo/thinkpad/x1/7th-gen/default.nix)
- [TLP FAQ: power-profiles-daemon](https://linrunner.de/tlp/faq/ppd.html)
- [libfprint supported devices](https://fprint.freedesktop.org/supported-devices.html)
- [throttled](https://github.com/erpalma/throttled)
- [NixOS Wiki: Laptop](https://wiki.nixos.org/wiki/Laptop)
