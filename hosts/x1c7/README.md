# Host: x1c7 (ThinkPad X1 Carbon Gen 7)

Lenovo ThinkPad X1 Carbon Gen 7 (20QES11500) running NixOS with Niri (Wayland), tuned for high responsiveness, quiet thermal management, and long battery life.

## Hardware Specs
- **CPU:** Intel Core i7-8565U (Whiskey Lake-U, 4C/8T, 1.80 GHz - 4.60 GHz)
- **iGPU:** Intel UHD Graphics 620
- **RAM:** 16 GB LPDDR3-2133 (soldered)
- **Storage:** Samsung PM981 256 GB NVMe SSD (`MZVLB256HBHQ-000L7`)
- **Display:** 14" FHD (1920x1080) IPS BOE NE140FHM-N61 (`eDP-1`)
- **Network:** Intel Wireless-AC 9560 (CNVi, `iwlwifi`) / Bluetooth 5.0
- **Audio:** Intel HDA with Sound Open Firmware (SOF DSP)
- **Input / Auth:** Synaptics TouchPad & TrackPoint, Synaptics Prometheus Fingerprint (`06cb:00bd`)

## Configuration Summary
- **Profile:** `desktop`
- **Kernel:** `pkgs.linuxPackages_xanmod` (low latency, high interactive responsiveness)
- **Nebula Mesh:** `10.0.0.101` (groups: `client`, `mgmt`)
- **Key Modules & Tuning:**
  - **Power & Thermals:** TLP battery charge thresholds (75/80%), `throttled` PL1/PL2 power envelope management, Noctalia power-profile D-Bus widget integration.
  - **Memory & Swap:** zram (100% RAM) + 16 GiB swapfile with `vm.watermark_scale_factor = 125` to eliminate OOM spikes during parallel builds.
  - **Audio Fix:** `services/audio.nix` patches ALSA UCM / PipeWire to prevent internal speakers from disappearing when HDMI displays are plugged in.
  - **Authentication:** Noctalia greeter on `eDP-1`, fingerprint authentication via `fprintd` integrated across PAM services (TLP `USB_DENYLIST` disables autosuspend on `06cb:00bd`).

For complete technical deep-dives into power management, throttled limits, sleep states, and audio patches, see [`docs/hardware/thinkpad-x1c7.md`](../../docs/hardware/thinkpad-x1c7.md).

## Installation
Follow the unified host installation guide in [`docs/operations/adding-a-host.md`](../../docs/operations/adding-a-host.md).

## Quick Operations
```bash
# Local rebuild with Polkit authentication
pkexec --keep-cwd nixos-rebuild switch --flake .#x1c7

# Temporary full battery charge
sudo tlp fullcharge

# Enroll fingerprint
fprintd-enroll
```

## References
- Comprehensive tuning guide: [`docs/hardware/thinkpad-x1c7.md`](../../docs/hardware/thinkpad-x1c7.md)
- Network topology: [`docs/architecture/network-topology.md`](../../docs/architecture/network-topology.md)
- Adding a new host: [`docs/operations/adding-a-host.md`](../../docs/operations/adding-a-host.md)
