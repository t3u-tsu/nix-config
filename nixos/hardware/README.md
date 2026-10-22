# Hardware Modules (`nixos/hardware/`)

Hardware drivers, GPU acceleration, and system diagnostic tooling.

## Modules

| File | Purpose | Key Options |
| :--- | :--- | :--- |
| `nvidia.nix` | NVIDIA driver management, PRIME offload/sync, and dynamic power management. | `my.hardware.nvidia.*` |
| `pc-tools.nix` | Hardware health and diagnostic tools (`nvme-cli`, `smartmontools`). | `my.hardware.pc-tools.enable` |
| `default.nix` | Hardware module aggregator. | — |

## NVIDIA Driver Configurations

The `nvidia.nix` module supports integrated offload and dedicated sync modes:

| Feature / Mode | Nix Option | Description |
| :--- | :--- | :--- |
| **PRIME Offload** | `my.hardware.nvidia.prime.offload.enable = true` | Default battery-saving configuration. iGPU renders display; dGPU executes on demand via `nvidia-offload`. |
| **PRIME Sync** | `my.hardware.nvidia.prime.sync.enable = true` | Dedicated rendering on the dGPU under X11. Under Wayland compositors (Niri), set `WLR_DRM_DEVICES`. |
| **Open Modules** | `my.hardware.nvidia.open = true` | Uses open-source kernel modules (Turing and newer architectures). |
| **Power Management** | `my.hardware.nvidia.powerManagement.finegrained = true` | Enables Runtime D3 (RTD3) dynamic power gating (requires PRIME offload). |

### Example: PRIME Offload with Open Modules

```nix
my.hardware.nvidia = {
  enable = true;
  open = true;
  powerManagement = {
    enable = true;
    finegrained = true;
  };
  prime = {
    enable = true;
    offload.enable = true;
    sync.enable = false;
    nvidiaBusId = "PCI:1:0:0";
    amdgpuBusId = "PCI:7:0:0";
  };
};
```

## References

- Hybrid GPU architecture: [`docs/hardware/hybrid-gpu.md`](../../docs/hardware/hybrid-gpu.md)
- Storage & ZFS configuration: [`docs/hardware/storage-zfs.md`](../../docs/hardware/storage-zfs.md)
