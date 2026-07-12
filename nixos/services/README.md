# Backup System (Restic)

This directory manages the global backup configuration using Restic.

## Structure

- **Sender Module (`default.nix`)**: 
  Automates local and remote backups when `my.backup` is enabled on a host.
- **Receiver Module (`receiver.nix`)**: 
  Configuration for the server receiving backup data (currently `kagutsuchi-sama`). Includes dedicated user and SFTP restrictions.

## Policy

### Destinations
1.  **Local**: High-reliability disks on each machine (e.g., ZFS Mirror on shosoin-tan).
2.  **Remote**: Large HDD on `kagutsuchi-sama` (10.0.1.3).

### Backup Targets (shosoin-tan)
- `/srv/minecraft`: All Minecraft world data.
- `/var/lib/minecraft-discord-bridge`: Discord Bridge database (bridge.db).

## Operational Commands

### Check Status
```bash
# Local backup status
sudo systemctl status restic-backups-local-backup.service
# Remote backup status
sudo systemctl status restic-backups-remote-backup.service
```

### Manual Run
```bash
sudo systemctl start restic-backups-remote-backup.service
```

### List Snapshots
```bash
# For local repo
sudo restic -r /mnt/tank-1tb/backups/minecraft snapshots
# For remote repo
sudo restic -r sftp:restic-shosoin@10.0.1.3:/mnt/data/backups/shosoin-tan snapshots
```

## Restoration Procedure

1. **Mount the backup to browse files (recommended):**
   ```bash
   mkdir /tmp/restore-view
   sudo restic -r /mnt/tank-1tb/backups/minecraft mount /tmp/restore-view
   ```
2. **Or restore specific files directly:**
   ```bash
   sudo restic -r <repo_path> restore <ID> --target / --include "/var/lib/minecraft-discord-bridge/bridge.db"
   ```
3. **Restore to custom target:**
   ```bash
   sudo restic -r <repo_path> restore <ID> --target /path/to/restore
   ```

## Notes
- Remote connections require `programs.ssh.extraConfig` to specify the identity file.
- The receiver side (`receiver.nix`) is restricted to SFTP only for security reasons.
