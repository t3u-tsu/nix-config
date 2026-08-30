# Hardware Modules

Hardware-specific system configuration and driver integration.

## Modules

- **`nvidia.nix`**: Centralized NVIDIA driver settings, hardware acceleration, and hybrid GPU configurations (PRIME offload/sync).
  - Provides options under `my.hardware.nvidia.*` to toggle NVIDIA support, select the kernel module variant, configure power management, and set bus IDs.
  - **Offload mode** (`my.hardware.nvidia.prime.offload.enable`, default): hybrid graphics for battery saving on laptops — the iGPU renders by default and the dGPU is activated on demand via the generated `nvidia-offload` command.
  - **Sync mode** (`my.hardware.nvidia.prime.sync.enable`): discrete GPU always active for gaming/workstations. **X11-only** — it has no effect under Wayland compositors (e.g. niri); use `WLR_DRM_DEVICES` to pick the primary renderer instead.
  - `my.hardware.nvidia.open`: use the open-source NVIDIA kernel modules (Turing or newer, e.g. RTX 30-series). Requires a package that provides an `.open` attribute.
  - `my.hardware.nvidia.powerManagement`: systemd suspend/resume integration (`enable`) and Runtime D3 power gating (`finegrained`). Note the nixpkgs assertions: `finegrained` requires PRIME offload and is incompatible with sync mode.
- **`pc-tools.nix`**: Hardware-specific tools for physical PCs/servers (`nvme-cli`, `smartmontools`) behind `my.hardware.pc-tools.enable`.
- **`default.nix`**: Imports the hardware modules.

## Configuration Example

Battery-first PRIME offload with open modules, RTD3 power management and a CachyOS-built driver:

```nix
my.hardware.nvidia = {
  enable = true;
  open = true;
  powerManagement = {
    enable = true;
    finegrained = true; # requires offload
  };
  prime = {
    enable = true;
    offload.enable = true; # default; nvidia-offload command is generated
    sync.enable = false;
    nvidiaBusId = "PCI:1:0:0";
    amdgpuBusId = "PCI:7:0:0";
  };
};
```
