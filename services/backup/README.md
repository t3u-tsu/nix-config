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

### Retention Policy
- Last 7 days
- Last 4 weeks
- Last 6 months
(Older snapshots are automatically pruned)

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

1.  Identify the Snapshot ID using the list command above.
2.  Run the restore command:
    ```bash
    sudo restic -r <repo_path> restore <ID> --target /path/to/restore
    ```

## Notes
- Remote connections require `programs.ssh.extraConfig` to specify the identity file.
- The receiver side (`receiver.nix`) is restricted to SFTP only for security reasons.
