# Host: HOSTNAME

Short description of this machine (role, hardware headline).

## Hardware Specs
- **CPU**:
- **GPU**:
- **RAM**:
- **Storage**:
  - ... (by-id names, mount points)

## Role / Services
- (what this host runs, e.g. Nebula member, Minecraft server, ...)
- Nebula IP: `10.0.0.5` (group: mgmt)

## Deployment
```bash
sudo nixos-rebuild switch --flake .#HOSTNAME
```

For remote hosts over the Nebula mesh:
```bash
nixos-rebuild switch --flake .#HOSTNAME --target-host t3u@10.0.0.5 --sudo --ask-sudo-password
```

## Installation (clean install)
1. Boot the NixOS installer, partition disks per `hardware.nix`.
2. Place the age key: `sudo mkdir -p /mnt/var/lib/sops-nix` and copy
   `/var/lib/sops-nix/key.txt` (derived from the SSH host key) before install:
   ```bash
   ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub   # register in .sops.yaml first
   ```
3. Install:
   ```bash
   sudo NIXPKGS_ALLOW_UNFREE=1 nixos-install --flake .#HOSTNAME
   ```

See `hosts/README.md` for the full add-a-host workflow.