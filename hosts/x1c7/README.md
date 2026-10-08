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

Power and thermal management on ThinkPad with Intel processors operates across
three cooperating layers:
1. **Platform Profile (ACPI DYTC)**: Tells the Lenovo Embedded Controller (EC)
   which fan curve and thermal table to use (`/sys/firmware/acpi/platform_profile`).
2. **Energy Performance Preference (Intel HWP EPP)**: Biases autonomous CPU
   frequency scaling between latency and power efficiency
   (`/sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference`).
3. **Scaling Governor (intel_pstate)**: Kernel driver operation mode
   (`/sys/devices/system/cpu/cpu*/cpufreq/scaling_governor`).

### TLP

nixos-hardware's `common/pc/laptop` enables `services.tlp` and excludes
`power-profiles-daemon` and `tuned`.

- **Charge thresholds 75/80.** Trades ~20% runtime for slower capacity loss on
  AC (431 cycles with negligible measured wear). `sudo tlp fullcharge`
  temporarily lifts the threshold to 100% until unplugged.
- **`services.tlp.pd`** exposes the `net.hadess.PowerProfiles` D-Bus interface
  backed by TLP so Noctalia's `power_profile` bar widget functions normally.
- **Governor and EPP.** Per the
  [Linux Kernel intel_pstate documentation](https://www.kernel.org/doc/html/latest/admin-guide/pm/intel_pstate.html)
  and [TLP processor settings](https://linrunner.de/tlp/settings/processor.html),
  active HWP mode requires the `powersave` governor on both AC and battery. A
  `performance` governor forces EPP to `performance` (0) and rejects EPP writes
  with `EBUSY`, which would prevent frequency from dropping at idle. Under `powersave`:
  - **AC**: `CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance"` allows cores
    to boost to 4.6 GHz under load while idling at 800 MHz. `CPU_HWP_DYN_BOOST_ON_AC = 1`
    adds dynamic boost for UI responsiveness.
  - **Battery**: `CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power"` biases frequency
    transitions toward power efficiency while preserving responsiveness.
  - **Low Battery**: `CPU_ENERGY_PERF_POLICY_ON_SAV = "power"` minimizes power consumption.
- **Platform Profile.** Per [TLP platform settings](https://linrunner.de/tlp/settings/platform.html):
  - `PLATFORM_PROFILE_ON_AC = "balanced"`: Keeps fan curves quiet during ordinary
    desktop tasks on AC, leaving maximum performance to be selected via Noctalia's
    widget when heavy sustained workloads occur.
  - `PLATFORM_PROFILE_ON_BAT = "balanced"`: Balances chassis comfort and fan noise.
- **PCIe ASPM.** `PCIE_ASPM_ON_BAT = "powersave"` moves PCIe links (NVMe, Intel
  9560 Wi-Fi, Thunderbolt) into lower-power link states on battery.

### throttled

[throttled](https://github.com/erpalma/throttled) fixes the Lenovo Linux thermal bug
where the EC throttles the CPU prematurely
([ArchWiki](https://wiki.archlinux.org/title/Lenovo_ThinkPad_X1_Carbon_(Gen_7)#Power_management/Throttling_issues)
and [Issue 150](https://github.com/erpalma/throttled/issues/150)).

Upstream defaults of 44 W / 95 C exceed what the single-fan, dual-heatpipe
chassis can sustainably dissipate. Limits are aligned with the
[Intel Core i7-8565U specifications](https://www.intel.co.jp/content/www/jp/ja/products/sku/149091/intel-core-i78565u-processor-8m-cache-up-to-4-60-ghz/specifications.html):
- **AC**:
  - `PL1_Tdp_W: 25` (28 s duration): Configurable TDP-up limit. Allows all cores
    to sustain ~3.0 GHz during heavy compilation.
  - `PL2_Tdp_W: 35` (0.002 s window): Short-term burst headroom. Absorbs brief
    execution spikes through heatpipe thermal capacity.
  - `Trip_Temp_C: 90`: Headroom for PL2 bursts below the 100 C TjMax, staying
    below Windows default (97 C) to maintain chassis comfort.
- **Battery**:
  - `PL1_Tdp_W: 15` (28 s duration): Nominal 15 W TDP. Prevents sluggishness under
    moderate multi-core work while keeping power draw reasonable.
  - `PL2_Tdp_W: 25` (0.002 s window): Configurable TDP-up burst limit for UI fluidity.
  - `Trip_Temp_C: 85`: Conservative thermal ceiling for lap use.

Voltage offset fields are omitted because firmware locks MSR 0x150 against
undervolting on Whiskey Lake. After changing `/etc/throttled.conf`, run
`sudo systemctl restart throttled` because Nix store mtimes do not change.

## Memory and swap

NixOS default reclaim timings, combined with up to 8 parallel Nix builds, drove
this 16 GB machine into OOM kills of `rustc`, `nix`, `cudafe++` and `zig`, with
single processes reaching ~10 GB of anonymous memory.

- **zram**: `memoryPercent = 100` and `priority = 100`. [`hardware.nix`](hardware.nix)
  records why those values, and the Hibernation section covers the interaction.
- **Swapfile**: 16 GiB at `/var/lib/swapfile`, matching RAM so that a
  hibernation image fits.
- **sysctls**: `vm.swappiness = 180`, `vm.watermark_boost_factor = 0`,
  `vm.watermark_scale_factor = 125` and `vm.page-cluster = 0`, taken from the
  Arch Wiki's zram tuning. The NixOS defaults, `watermark_scale_factor = 10` in
  particular, begin reclaiming far too late.
- Hibernation is verified and takes roughly 40 seconds; see the section below
  and [`services/power.nix`](services/power.nix).

## Hibernation

Hibernation works, writing an image of RAM to the swapfile and resuming from it
on the next boot.

- **Do not set `boot.resumeDevice`.** It puts `resume=<root partition>` on the
  kernel command line, and the swap here is a file *inside* that partition
  rather than the partition itself, so logind refuses with "Specified resume
  device is missing or is not an active swap device". With a systemd initrd on
  UEFI, systemd-sleep picks a swap space, records it in the `HibernateLocation`
  EFI variable, and `systemd-hibernate-resume` reads it back on the next boot.
  The kernel then reports the swapfile offset in `/sys/power/resume_offset`
  without any manual `resume_offset`.
- **zram cannot hold the image** because it is volatile. The disk swapfile in
  [`hardware.nix`](hardware.nix) exists partly for this, and systemd ignores
  zram devices when choosing a hibernation target. The swapfile's
  kernel-assigned priority is negative, keeping zram first in ordinary use.
- **`lockdown=integrity` would forbid hibernation**, so the kernel parameter is
  deliberately absent.
- `services.upower.criticalPowerAction = "Hibernate"` writes the image rather
  than powering off when the battery runs critically low.

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

The sensor is touch-based: **press and lift** rather than swiping. Enrolling a
finger here took eight `enroll-stage-passed` lines before `enroll-completed`,
and the device reports itself as "Synaptics Sensors (press)". Should
verification fail, vary how long the finger is held down.

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

If the reader stops working after suspend or during cold boots, the Arch
Wiki's Fprint page lists the usual causes: fprintd starting before the USB
device is re-initialised or waking from autosuspend with protocol timeouts.
TLP's `USB_DENYLIST` keeps `power/control` at `on` (disabling autosuspend),
and a udev rule keeps `power/persist` at `1` on `06cb:00bd`. S3 sleep is
configured in the BIOS.

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
Copy its `fileSystems` and kernel-module lines into `hosts/x1c7/hardware.nix`,
but keep the `swapDevices` entry: it names a swapfile rather than a partition,
so `nixos-generate-config` reports an empty list that must not replace it. The
installer has no `github-nix-config-private` ssh alias yet, so run
[Bootstrap the private flake input](../README.md#bootstrap-the-private-flake-input)
first, then install:
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
- [throttled issue 150 (X1C7 & TDP tuning)](https://github.com/erpalma/throttled/issues/150)
- [Intel Core i7-8565U Processor Specifications](https://www.intel.co.jp/content/www/jp/ja/products/sku/149091/intel-core-i78565u-processor-8m-cache-up-to-4-60-ghz/specifications.html)
- [Linux Kernel intel_pstate documentation](https://www.kernel.org/doc/html/latest/admin-guide/pm/intel_pstate.html)
- [TLP Documentation: Processor settings](https://linrunner.de/tlp/settings/processor.html)
- [TLP Documentation: Platform profile settings](https://linrunner.de/tlp/settings/platform.html)
- [NixOS Wiki: Laptop](https://wiki.nixos.org/wiki/Laptop)
