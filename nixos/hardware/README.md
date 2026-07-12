# Hardware Modules

Hardware-specific system configuration and driver integration.

## Modules

- **`nvidia.nix`**: Centralized NVIDIA driver settings, hardware acceleration, and hybrid GPU configurations (PRIME offload/sync).
  - Provides options under `my.hardware.nvidia.*` to toggle NVIDIA support and configure bus IDs.
  - Supports both **Sync mode** (discrete GPU always active for gaming/workstations) and **Offload mode** (hybrid graphics for battery saving on laptops) under `my.hardware.nvidia.prime`.
- **`default.nix`**: Imports the hardware modules.

## Configuration Example

To enable hybrid NVIDIA sync mode on a host:

```nix
my.hardware.nvidia = {
  enable = true;
  prime = {
    enable = true;
    sync.enable = true;
    nvidiaBusId = "PCI:1:0:0";
    amdgpuBusId = "PCI:7:0:0";
  };
};
```
