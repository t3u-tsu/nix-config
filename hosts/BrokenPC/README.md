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

- **Display & UI Isolation:** Hardware-level 3D rasterization is defective on the dGPU. Niri and 3D graphics (Steam) run exclusively on the AMD Radeon 680M iGPU via `WLR_DRM_DEVICES` (PCI by-path) and `my.services.desktop.gaming.nvidiaOffload.enable = false`.
- **CUDA Matrix Acceleration:** Matrix compute (GEMM) units remain functional. The dGPU runs local LLM matrix workloads via CUDA (`services/llama.nix`, targeting SM 8.6).
- **Power Optimization:** When idle, the dGPU powers down via open kernel modules and RTD3 (`powerManagement.finegrained = true`), saving battery.

## Configuration Summary

| Property | Value |
| :--- | :--- |
| **Profile** | `desktop` |
| **Nebula Mesh** | `10.0.0.100` (groups: `mgmt`, `app`) |
| **Compositor & Shell** | Niri Wayland compositor, Noctalia desktop shell & greeter |
| **Key Services** | Local LLM inference server (`my.home.programs.llama`), SOPS secrets |

## Quick Operations

```bash
# Local system rebuild
sudo nixos-rebuild switch --flake .#BrokenPC
```

## References

- Hybrid GPU architecture & LLM tuning: [`docs/hardware/hybrid-gpu.md`](../../docs/hardware/hybrid-gpu.md)
- Network topology: [`docs/architecture/network-topology.md`](../../docs/architecture/network-topology.md)
- Host addition runbook: [`docs/operations/adding-a-host.md`](../../docs/operations/adding-a-host.md)
