# Host: kagutsuchi-sama (Compute & Backup Server)

Tower server for compilation, GPU compute, and off-site Restic backup reception for `shosoin-tan`.

## Hardware Specifications

| Component | Specification | Details |
| :--- | :--- | :--- |
| **CPU** | Intel Xeon E5-2650 v2 | Ivy Bridge-EP, 8C/16T, 2.60 GHz |
| **GPU** | NVIDIA GeForce GTX 980 Ti | Maxwell, 6 GB VRAM |
| **RAM** | 16 GB DDR3 | ECC Registered |
| **Storage (System)** | 500 GB SATA SSD | `/boot` (512M fat32), `/` (ext4) |
| **Storage (Data)** | 3 TB SATA HDD | `/mnt/data` (ext4, backup storage) |

## Configuration Summary

| Property | Value |
| :--- | :--- |
| **Profile** | `tower-server` |
| **Nebula Mesh** | `10.0.0.3` (groups: `mgmt`) |
| **Roles** | Remote compute / build offload, Restic backup repository receiver |
| **SSH Policy** | Restricted to the `nebula0` overlay interface |

## Host Services & Modules

| File | Description | Options / Notes |
| :--- | :--- | :--- |
| [services/default.nix](services/default.nix) | Host service aggregator importing Nebula overlay and enabling the Restic backup receiver (`my.services.emergencySsh.enable = true;` is enabled by the `tower-server` profile). | `my.services.backup.receiver.enable = true;` |
| [services/nebula.nix](services/nebula.nix) | Nebula encrypted overlay mesh node definition. | Node IP `10.0.0.3`, group `mgmt` |

## Backup Storage

Runs SFTP receiver account `restic-shosoin` storing encrypted Restic snapshots in `/mnt/data/backups/shosoin-tan`. A restricted `internal-sftp` authorized key authenticates access over Nebula.

## Quick Operations

```bash
# Remote deployment over Nebula
nixos-rebuild switch --flake .#kagutsuchi-sama --target-host t3u@10.0.0.3 --sudo --ask-sudo-password
```

## References

- Backup architecture & recovery: [docs/operations/backup-and-restore.md](../../docs/operations/backup-and-restore.md)
- Network topology: [docs/architecture/network-topology.md](../../docs/architecture/network-topology.md)
- Host addition runbook: [docs/operations/adding-a-host.md](../../docs/operations/adding-a-host.md)
