# Host: x1c7 (ThinkPad X1 Carbon Gen 7)

Lenovo ThinkPad X1 Carbon Gen 7 (20QES11500) running NixOS with Niri (Wayland), tuned for low latency, quiet thermals, and battery efficiency.

## Hardware Specifications

| Component | Specification | Details |
| :--- | :--- | :--- |
| **CPU** | Intel Core i7-8565U | Whiskey Lake-U, 4C/8T, 1.80 GHz - 4.60 GHz |
| **iGPU** | Intel UHD Graphics 620 | Primary display renderer |
| **RAM** | 16 GB LPDDR3-2133 | Soldered dual-channel |
| **Storage** | 256 GB NVMe SSD (`MZVLB256HBHQ`) | Samsung PM981 |
| **Display** | 14" FHD (1920x1080) IPS | BOE NE140FHM-N61 (`eDP-1`) |
| **Network** | Intel Wireless-AC 9560 | CNVi 802.11ac (`iwlwifi`), Bluetooth 5.0 |
| **Audio** | Intel HDA with SOF DSP | Sound Open Firmware |
| **Biometrics** | Synaptics Prometheus Fingerprint | USB ID `06cb:00bd` (`fprintd`) |

## Configuration Summary

| Property | Value |
| :--- | :--- |
| **Profile** | `desktop` |
| **Kernel** | `pkgs.linuxPackages_xanmod` (low latency, high interactive responsiveness) |
| **Nebula Mesh** | `10.0.0.101` (groups: `mgmt`, `app`) |
| **Compositor & Shell** | Niri Wayland compositor, Noctalia desktop shell & greeter |

## Key Optimizations

- **Power & Thermals:** TLP battery thresholds (75/80%), `throttled` PL1/PL2 power envelope management, Noctalia power-profile D-Bus widget.
- **Memory & Swap:** zram (100% RAM) + 16 GiB swapfile with `vm.watermark_scale_factor = 125` to prevent OOM kills during parallel Nix builds.
- **Audio Routing:** `services/audio.nix` patches ALSA UCM / PipeWire to keep internal speakers active when external HDMI displays connect.
- **Authentication:** Noctalia greeter on `eDP-1`, fingerprint authentication via `fprintd` integrated across PAM services (TLP `USB_DENYLIST` disables autosuspend on `06cb:00bd`).

## Quick Operations

```bash
# Local system rebuild
sudo nixos-rebuild switch --flake .#x1c7

# Temporarily charge battery to 100%
sudo tlp fullcharge

# Enroll fingerprint
fprintd-enroll
```

## References

- ThinkPad X1C7 hardware guide: [`docs/hardware/thinkpad-x1c7.md`](../../docs/hardware/thinkpad-x1c7.md)
- Network topology: [`docs/architecture/network-topology.md`](../../docs/architecture/network-topology.md)
- Host addition runbook: [`docs/operations/adding-a-host.md`](../../docs/operations/adding-a-host.md)
