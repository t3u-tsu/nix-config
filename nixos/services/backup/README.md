# Backup Services (`nixos/services/backup/`)

Fleet backup automation using [Restic](https://restic.net/) for encrypted, deduplicated, and authenticated snapshots.

## Architecture & Topology

Backups follow a two-tier strategy combining local high-speed recovery with off-site disaster recovery:

| Destination | Target Storage | Transport / Protocol | Schedule |
| :--- | :--- | :--- | :--- |
| **Local Snapshot** | `/mnt/tank-1tb/backups/minecraft` (ZFS Mirror) | Local filesystem repository | Every 2 hours |
| **Remote Snapshot** | `sftp:restic-shosoin@10.0.0.3:/mnt/data/backups/shosoin-tan` | SFTP over Nebula mesh (`kagutsuchi-sama`) | Every 2 hours |

### Backup Targets

- `/srv/minecraft`: Minecraft Paper server directories and world files.
- `/var/lib/minecraft-discord-bridge`: Discord bridge SQLite database (`bridge.db`).

## Modules

| File | Purpose | Key Option |
| :--- | :--- | :--- |
| [`default.nix`](default.nix) | Client sender module scheduling periodic local and remote snapshots via systemd timers. | `my.services.backup.enable` |
| [`receiver.nix`](receiver.nix) | Server receiver module configuring the SFTP-only user `restic-shosoin` with a forced `internal-sftp` command. | `my.services.backup.receiver.enable` |

## Operational Commands

### Check Timer and Service Status

```bash
# Check timer and last execution status
systemctl status restic-backups-local-backup.timer
systemctl status restic-backups-remote-backup.service
```

### Manual Trigger

```bash
# Trigger immediate backup run
sudo systemctl start restic-backups-remote-backup.service
```

### Snapshot Inspection

```bash
# Inspect local repository
sudo restic -r /mnt/tank-1tb/backups/minecraft snapshots

# Inspect remote repository over Nebula
sudo restic -r sftp:restic-shosoin@10.0.0.3:/mnt/data/backups/shosoin-tan snapshots
```

### Restoration Workflows

```bash
# Method 1: Mount repository as a read-only FUSE filesystem
mkdir -p /tmp/restore-view
sudo restic -r /mnt/tank-1tb/backups/minecraft mount /tmp/restore-view

# Method 2: Restore specific database directly
sudo restic -r /mnt/tank-1tb/backups/minecraft restore latest \
  --target / \
  --include "/var/lib/minecraft-discord-bridge/bridge.db"

# Method 3: Restore full snapshot to alternate directory
sudo restic -r /mnt/tank-1tb/backups/minecraft restore latest --target /tmp/restored-data
```

## References

- Backup & disaster recovery runbook: [`docs/operations/backup-and-restore.md`](../../../docs/operations/backup-and-restore.md)
- Storage & ZFS configuration: [`docs/hardware/storage-zfs.md`](../../../docs/hardware/storage-zfs.md)
- Host specifications: [`hosts/shosoin-tan/`](../../../hosts/shosoin-tan/README.md) and [`hosts/kagutsuchi-sama/`](../../../hosts/kagutsuchi-sama/README.md)
