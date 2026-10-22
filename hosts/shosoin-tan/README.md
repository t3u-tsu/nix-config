# Host: shosoin-tan (Minecraft & General-Purpose Server)

Home tower server hosting Minecraft services, Discord Bridge, and Restic backups with ZFS Mirror storage.

## Hardware Specifications

| Component | Specification | Details |
| :--- | :--- | :--- |
| **CPU** | Intel Core i7-870 | Nehalem, 4C/8T, 2.93 GHz |
| **GPU** | NVIDIA Quadro K2200 | Maxwell architecture |
| **RAM** | 16 GB DDR3 | Non-ECC |
| **Storage (System)** | 480 GB SATA SSD | MBR layout (`/boot` 500M vfat, `/` ext4) |
| **Storage (ZFS Pool)** | 2x 1 TB SATA HDDs | ZFS Mirror pool `tank-1tb` (`/mnt/tank-1tb`) |
| **Storage (Auxiliary)** | 320 GB SATA HDD | `/mnt/data-320gb` (ext4) |

## Configuration Summary

| Property | Value |
| :--- | :--- |
| **Profile** | `tower-server` |
| **Bootloader** | GRUB on MBR (`boot.loader.grub.efiSupport = false`) |
| **Nebula Mesh** | `10.0.0.4` (groups: `mgmt`, `app`) |
| **Key Services** | Minecraft Paper server, Discord Bridge bot, multi-tier Restic backups |

## Key Services

- **Minecraft Server:** Paper server running under `/srv/minecraft`. Forwards public traffic (`tcp/25565`) from `torii-chan` over Nebula.
- **Discord Bridge:** Chat bridge bot communicating through UNIX socket at `/run/minecraft-discord-bridge/bridge.sock`.
- **Multi-Tier Restic Backups:** Runs bi-hourly snapshots to local ZFS mirror (`/mnt/tank-1tb/backups/minecraft`) and off-site over Nebula to `kagutsuchi-sama` (`10.0.0.3`).

## Quick Operations

```bash
# Remote deployment over Nebula
nixos-rebuild switch --flake .#shosoin-tan --target-host t3u@10.0.0.4 --sudo --ask-sudo-password

# Check ZFS pool status
zpool status tank-1tb
```

## References

- Backup & disaster recovery runbook: [`docs/operations/backup-and-restore.md`](../../docs/operations/backup-and-restore.md)
- ZFS & Legacy BIOS architecture: [`docs/hardware/storage-zfs.md`](../../docs/hardware/storage-zfs.md)
- Network topology: [`docs/architecture/network-topology.md`](../../docs/architecture/network-topology.md)
- Host addition runbook: [`docs/operations/adding-a-host.md`](../../docs/operations/adding-a-host.md)
