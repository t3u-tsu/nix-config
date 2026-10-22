# Host: BrokenPC (HP Victus 16-e1065AX)

Secondary portable laptop deployed at Site A and off-site, running NixOS with Niri (Wayland) on an AMD iGPU and compute-only NVIDIA dGPU.

## Hardware Specifications

| Component | Specification | Details |
| :--- | :--- | :--- |
| **CPU** | AMD Ryzen 7 6800H | Zen 3+, 8C/16T, up to 4.7 GHz |
| **iGPU** | AMD Radeon 680M | RDNA2 (Primary display renderer) |
| **dGPU** | NVIDIA GeForce RTX 3050 Ti Mobile | Ampere 4 GB (Matrix compute only; 3D rasterization defective) |
| **RAM** | 16 GB DDR5-4800 | Dual channel |
| **Storage 1** | 512 GB NVMe SSD (`MTFDKBA512TFH`) | ESP (`/boot` 512M fat32), Swap (8G), Root (`/` ext4) |
| **Storage 2** | 1 TB NVMe SSD (`FIKWOT_FN500`) | Fast scratch & LLM models (`/data` ext4) |

## GPU Separation & Workload Allocation

- Routes Niri and 3D graphics (Steam) to the AMD Radeon 680M iGPU via `WLR_DRM_DEVICES` (PCI by-path) and `my.services.desktop.gaming.nvidiaOffload.enable = false` because dGPU 3D rasterization is defective.
- Runs local LLM matrix workloads on the functional dGPU compute (GEMM) units via CUDA ([services/llama.nix](services/llama.nix), targeting SM 8.6).
- Powers down the dGPU when idle using open kernel modules and RTD3 (`powerManagement.finegrained = true`).

## Configuration Summary

| Property | Value |
| :--- | :--- |
| **Profile** | `desktop` |
| **Nebula Mesh** | `10.0.0.100` (groups: `mgmt`, `app`) |
| **Compositor & Shell** | Niri Wayland compositor, Noctalia desktop shell & greeter |
| **Key Services** | Local LLM inference server (`my.home.programs.llama`), SOPS secrets |

## Host Services & Modules

| File | Description | Options / Notes |
| :--- | :--- | :--- |
| [services/default.nix](services/default.nix) | Host service aggregator importing local LLM inference and Nebula overlay modules. | Imported in [default.nix](default.nix) |
| [services/llama.nix](services/llama.nix) | Local LLM inference server using CUDA on the compute-only RTX 3050 Ti Mobile dGPU. | `my.home.programs.llama.enable = true;` |
| [services/nebula.nix](services/nebula.nix) | Nebula encrypted overlay mesh node definition. | Node IP `10.0.0.100`, groups: `mgmt`, `app` |

## Quick Operations

```bash
# Local system rebuild
sudo nixos-rebuild switch --flake .#BrokenPC

# Recover touchpad and I2C controller without rebooting
ysh scripts/restart-touchpad.ysh
```

## Hardware Quirks & Troubleshooting

| Quirk / Symptom | Cause | Mitigation & Workaround |
| :--- | :--- | :--- |
| Touchpad Freezing & I2C Timeout | Synaptics touchpad (`SYNA32CD:00`) on AMD DesignWare I2C bus (`AMDI0010:03`) freezes when controller enters runtime autosuspend. | Locked to `on` via udev rule and restored in `powerManagement.resumeCommands`. Manual recovery via `ysh scripts/restart-touchpad.ysh`. |
| Boot Hang (Black Screen & Spinning Fans) | HP Victus 16 motherboard (`8A22`) EC state hang during power transitions. | Disconnect AC charger and perform a hard EC reset by holding the power button for 20–30 seconds. |

## References

- Hybrid GPU architecture & LLM tuning: [docs/hardware/hybrid-gpu.md](../../docs/hardware/hybrid-gpu.md)
- Network topology: [docs/architecture/network-topology.md](../../docs/architecture/network-topology.md)
- Host addition runbook: [docs/operations/adding-a-host.md](../../docs/operations/adding-a-host.md)
