# Host: sando-kun (i7-860 Tower Server)

General-purpose legacy tower server running on BIOS/MBR partitioning with Intel Core i7-860.

## Hardware Specifications

| Component | Specification | Details |
| :--- | :--- | :--- |
| **CPU** | Intel Core i7-860 | Nehalem, 4C/8T, 2.80 GHz |
| **GPU** | NVIDIA GeForce 8400 GS | Tesla architecture, nouveau driver |
| **RAM** | 8 GB DDR3 | Non-ECC |
| **Storage (System)** | 250 GB SATA HDD (`ST9250320AS`) | MBR layout: swap, `/boot` (500M vfat), `/` (ext4) |
| **Storage (Scratch)**| 80 GB SATA HDD | `/mnt/scratch` (ext4) |

## Configuration Summary

| Property | Value |
| :--- | :--- |
| **Profile** | `tower-server` |
| **Bootloader** | GRUB on MBR (`boot.loader.grub.efiSupport = false`) |
| **Nebula Mesh** | `10.0.0.2` (groups: `server`, `mgmt`) |
| **SSH Policy** | Strictly bound to `nebula0` overlay interface |

## Quick Operations

```bash
# Remote deployment over Nebula
nixos-rebuild switch --flake .#sando-kun --target-host t3u@10.0.0.2 --sudo --ask-sudo-password
```

## References

- Legacy BIOS & storage architecture: [`docs/hardware/storage-zfs.md`](../../docs/hardware/storage-zfs.md)
- Network topology: [`docs/architecture/network-topology.md`](../../docs/architecture/network-topology.md)
- Host addition runbook: [`docs/operations/adding-a-host.md`](../../docs/operations/adding-a-host.md)
