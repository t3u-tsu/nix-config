# Host: sando-kun (i7-860 Tower Server)

Tower server running on BIOS/MBR partitioning with an Intel Core i7-860 processor.

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
| **Nebula Mesh** | `10.0.0.2` (groups: `mgmt`) |
| **SSH Policy** | Restricted to the `nebula0` overlay interface |

## Host Services & Modules

| File | Description | Options / Notes |
| :--- | :--- | :--- |
| [services/default.nix](services/default.nix) | Host service aggregator importing the Nebula overlay module (`my.services.emergencySsh.enable = true;` is enabled by the `tower-server` profile). | Imported in [default.nix](default.nix) |
| [services/nebula.nix](services/nebula.nix) | Nebula encrypted overlay mesh node definition. | Node IP `10.0.0.2`, group `mgmt` |

## Quick Operations

```bash
# Remote deployment over Nebula
nixos-rebuild switch --flake .#sando-kun --target-host t3u@10.0.0.2 --sudo --ask-sudo-password
```

## References

- Legacy BIOS & storage architecture: [docs/hardware/storage-zfs.md](../../docs/hardware/storage-zfs.md)
- Network topology: [docs/architecture/network-topology.md](../../docs/architecture/network-topology.md)
- Host addition runbook: [docs/operations/adding-a-host.md](../../docs/operations/adding-a-host.md)
