# shosoin-tan (Tower Server)

Tower server using ZFS for storage and NVIDIA Quadro for general purpose or basic display.

## Hardware Specs
- **CPU**: Intel Core i7 870
- **GPU**: NVIDIA Quadro K2200
- **Storage**:
  - 480GB SSD: Root (`/`)
  - 1TB HDD x2: ZFS Mirror (`tank-1tb`)
  - 320GB HDD x2: ZFS Mirror (`tank-320gb`)
  - 2TB HDD: Backup Partition (`ext4`)

## Initial Setup
1. Boot from NixOS installer.
2. Run `disko` to partition and format disks.
3. Install configuration using `nixos-install --flake .#shosoin-tan`.
