# Host: kagutsuchi-sama (Compute Server & Backup Receiver)

High-power tower server used for compute workloads and serving as the primary remote backup receiver for `shosoin-tan`.

## Hardware Specs
- **CPU:** Intel Xeon E5-2650 v2 (8C/16T, 2.60 GHz)
- **GPU:** NVIDIA GeForce GTX 980 Ti (Maxwell)
- **RAM:** 16 GB DDR3
- **Storage:**
  - 500 GB SSD (Root / Boot, ext4 / vfat)
  - 3 TB HDD (`/mnt/data`, ext4)

## Configuration Summary
- **Profile:** `tower-server`
- **Roles:**
  - **Compute Server:** GPU compute and heavy compilation workloads.
  - **Remote Backup Receiver:** Hosts SFTP receiver account `restic-shosoin` saving encrypted Restic snapshots to `/mnt/data/backups/shosoin-tan` (see [`docs/operations/backup-and-restore.md`](../../docs/operations/backup-and-restore.md)).
- **Nebula Mesh:** `10.0.0.3` (groups: `server`, `mgmt`, `backup-receiver`)
- **SSH Access:** Restricted to `nebula0` (Nebula mesh only).

## Installation
Follow the unified host installation guide in [`docs/operations/adding-a-host.md`](../../docs/operations/adding-a-host.md).

Disk partition layout:
- `/dev/sda`: 500 GB SSD (`/boot` 512M fat32, `/` ext4)
- `/dev/sdb`: 3 TB HDD (`/mnt/data` ext4)

## Quick Operations
```bash
# Rebuild remotely over Nebula
nixos-rebuild switch --flake .#kagutsuchi-sama --target-host t3u@10.0.0.3 --sudo --ask-sudo-password
```

## References
- Backup architecture & DR: [`docs/operations/backup-and-restore.md`](../../docs/operations/backup-and-restore.md)
- Network topology: [`docs/architecture/network-topology.md`](../../docs/architecture/network-topology.md)
- Adding a new host: [`docs/operations/adding-a-host.md`](../../docs/operations/adding-a-host.md)
