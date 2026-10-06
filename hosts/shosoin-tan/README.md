# Host: shosoin-tan (Minecraft & General-Purpose Server)

Tower server equipped with an Intel Core i7-870, SSD system drive, and a ZFS Mirror storage pool (`tank-1tb`), hosting the fleet Minecraft server, Discord Bridge, and multi-tier backup.

## Hardware Specs
- **CPU:** Intel Core i7-870 (Nehalem, 4C/8T, 2.93 GHz)
- **GPU:** NVIDIA Quadro K2200 (Maxwell)
- **RAM:** 16 GB DDR3
- **Storage:**
  - 480 GB SATA SSD: OS / Boot (MBR)
  - 1 TB SATA HDD x2: ZFS Mirror (`tank-1tb`, mounted at `/mnt/tank-1tb`)
  - 320 GB SATA HDD: Auxiliary storage (`/mnt/data-320gb`)

## Configuration Summary
- **Profile:** `tower-server`
- **Bootloader:** Legacy BIOS (MBR), `boot.loader.grub.efiSupport = false`
- **Nebula Mesh:** `10.0.0.4` (groups: `server`, `mgmt`, `app`)
- **Key Services:**
  - **Minecraft:** Paper server (`/srv/minecraft`, TCP 25565 forwarded from `torii-chan`).
  - **Discord Bridge:** Bot integration with socket at `/run/minecraft-discord-bridge/bridge.sock`.
  - **Multi-tier Restic Backup:** Runs every 2 hours, backing up both locally to `/mnt/tank-1tb/backups/restic` and remotely over Nebula to `kagutsuchi-sama` (`10.0.0.3`).

## Installation
Follow the unified host installation guide in [`docs/operations/adding-a-host.md`](../../docs/operations/adding-a-host.md).

Disk layout:
- `/dev/sda` (SSD): MBR partition table (`/boot` 500M vfat, `/` ext4)
- `/dev/sdb` & `/dev/sdc` (HDDs): ZFS Mirror pool `tank-1tb`
- `/dev/sdd` (HDD): `/mnt/data-320gb` (ext4)

## Quick Operations
```bash
# Rebuild remotely over Nebula
nixos-rebuild switch --flake .#shosoin-tan --target-host t3u@10.0.0.4 --sudo --ask-sudo-password

# Check ZFS pool status
zpool status tank-1tb
```

## References
- Backup & DR runbook: [`docs/operations/backup-and-restore.md`](../../docs/operations/backup-and-restore.md)
- ZFS & Legacy BIOS architecture: [`docs/hardware/storage-zfs.md`](../../docs/hardware/storage-zfs.md)
- Network topology: [`docs/architecture/network-topology.md`](../../docs/architecture/network-topology.md)
- Adding a new host: [`docs/operations/adding-a-host.md`](../../docs/operations/adding-a-host.md)
