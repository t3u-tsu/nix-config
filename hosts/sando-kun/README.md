# Host: sando-kun (i7-860 Tower Server)

General-purpose legacy tower server equipped with an Intel Core i7-860, 250 GB system HDD, and 80 GB scratch HDD.

## Hardware Specifications
- **CPU:** Intel Core i7-860 (Nehalem, 4C/8T, 2.80 GHz)
- **GPU:** NVIDIA GeForce 8400 GS (Tesla architecture, nouveau driver)
- **RAM:** 8 GB DDR3
- **Storage:**
  - 250 GB SATA HDD (`ata-ST9250320AS_5SW1VK4F`): OS / Boot (MBR)
  - 80 GB SATA HDD: `/mnt/scratch` (ext4)

## Configuration Summary
- **Profile:** `tower-server`
- **Bootloader:** Legacy BIOS (MBR), `boot.loader.grub.efiSupport = false`
- **Nebula Mesh:** `10.0.0.2` (groups: `server`, `mgmt`)
- **SSH Access:** Restricted to `nebula0` (Nebula mesh only).

## Installation
Follow the unified host installation guide in [`docs/operations/adding-a-host.md`](../../docs/operations/adding-a-host.md).

Disk layout (MBR / msdos):
- `/dev/sda`: 250 GB HDD (part1 = swap, part2 = `/boot` 500M vfat, part3 = `/` ext4)
- `/dev/sdb`: 80 GB HDD (`/mnt/scratch` ext4)

## Quick Operations
```bash
# Rebuild remotely over Nebula
nixos-rebuild switch --flake .#sando-kun --target-host t3u@10.0.0.2 --sudo --ask-sudo-password
```

## References
- Legacy BIOS & storage architecture: [`docs/hardware/storage-zfs.md`](../../docs/hardware/storage-zfs.md)
- Network topology: [`docs/architecture/network-topology.md`](../../docs/architecture/network-topology.md)
- Adding a new host: [`docs/operations/adding-a-host.md`](../../docs/operations/adding-a-host.md)
