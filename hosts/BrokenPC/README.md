# Host: BrokenPC (HP Victus 16-e1065AX)

Secondary portable laptop based at Base A and taken off-site, featuring a hybrid AMD iGPU and faulty NVIDIA dGPU configuration, running NixOS with Niri (Wayland).

## Hardware Specs
- **CPU:** AMD Ryzen 7 6800H (Zen 3+, 8C/16T, up to 4.7 GHz)
- **iGPU:** AMD Radeon 680M (RDNA2, primary display renderer)
- **dGPU:** NVIDIA GeForce RTX 3050 Ti Mobile (Ampere 4 GB, **hardware rendering defect**)
- **RAM:** 16 GB DDR5-4800
- **Storage:**
  - 512 GB NVMe SSD (`MTFDKBA512TFH`): Root (`/`), Boot (`/boot`), Swap
  - 1 TB NVMe SSD (`FIKWOT_FN500`): Fast scratch & LLM storage (`/data`)

## GPU Separation & Local LLM Service
- **Display Renderer Isolation:** The dGPU suffers from a hardware-level 3D texture/rendering pipeline defect. All desktop display (Niri) and gaming rendering (Steam) are strictly locked to the stable AMD Radeon 680M iGPU via `WLR_DRM_DEVICES` (PCI by-path) and keeping `my.services.desktop.gaming.nvidiaOffload.enable = false` (default disabled).
- **CUDA & Local LLM (`llama.cpp`):** Matrix compute (GEMM) circuits remain fully functional. The dGPU is utilized as a dedicated CUDA inference accelerator for `llama-server` (`services/llama.nix`, targeting SM 8.6).
- **Power Management:** When idle, the dGPU is completely powered down via open kernel modules and RTD3 (`powerManagement.finegrained = true`), minimizing battery drain when used portably.
- For in-depth technical analysis and preset configurations, see [`docs/hardware/hybrid-gpu.md`](../../docs/hardware/hybrid-gpu.md).

## Configuration Summary
- **Profile:** `desktop`
- **Nebula Mesh:** `10.0.0.100` (groups: `mgmt`, `app`)
- **Mobility & Networking:** Operates both at Base A and off-site over Wi-Fi / mobile hotspots, accessing cluster services securely via Nebula (`10.0.0.0/24`).
- **Key Modules:**
  - Desktop: Niri Wayland compositor, Noctalia greeter & shell, Ghostty, Zen Browser
  - Services: Local LLM (`my.services.llama`), SOPS secrets

## Installation
Follow the unified host installation guide in [`docs/operations/adding-a-host.md`](../../docs/operations/adding-a-host.md).

Disk layout:
- `nvme0n1`: ESP (512M fat32), Swap (8G), Root (ext4)
- `nvme1n1`: `/data` (1 TB ext4)

## Quick Operations
```bash
# Local rebuild
sudo nixos-rebuild switch --flake .#BrokenPC
```

## References
- Hybrid GPU architecture & LLM tuning: [`docs/hardware/hybrid-gpu.md`](../../docs/hardware/hybrid-gpu.md)
- Network topology: [`docs/architecture/network-topology.md`](../../docs/architecture/network-topology.md)
- Adding a new host: [`docs/operations/adding-a-host.md`](../../docs/operations/adding-a-host.md)
