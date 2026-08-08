# Hostname: sando-kun (i7-860 Tower Server)

This host is a general-purpose tower server equipped with an Intel Core i7-860 and an 80GB HDD configuration. It follows the standard configuration established by `shosoin-tan` and `kagutsuchi-sama`.

## Hardware Specifications
- **CPU:** Intel Core i7-860 (1st Generation)
- **GPU:** GeForce 8400 GS (Tesla)
- **RAM:** 8GB
- **Storage:**
  - 250GB HDD (OS / Boot)
  - 80GB HDD (`scratch`)

## Installation Guide

Since this host uses older hardware, we use the following high-reliability installation procedure (similar to `shosoin-tan`) to minimize CPU load and ensure compatibility.

### Phase 1: Prepare Disks
1. **Execute Disko:** Run the following steps from another machine.
   ```bash
   nix build .#nixosConfigurations.sando-kun.config.system.build.diskoScript
   nix copy --to ssh://nixos@<IP> ./result
   ssh -t nixos@<IP> "sudo ./result --mode destroy,format,mount"
   ```

### Phase 2: Transfer Secret Key
```bash
ssh nixos@<IP> "sudo mkdir -p /mnt/var/lib/sops-nix"
cat ~/.config/sops/age/keys.txt | ssh nixos@<IP> "sudo tee /mnt/var/lib/sops-nix/key.txt > /dev/null"
```

### Phase 3: Build and Transfer System (Recommended)
To reduce CPU load on the target, we transfer the pre-built image from the build host.
1. **Build:** `nix build .#nixosConfigurations.sando-kun.config.system.build.toplevel`
2. **Transfer:** `nix copy --to ssh://nixos@<IP> ./result`
3. **Install:** `ssh nixos@<IP> "sudo nixos-install --system $(readlink -f ./result)"`

## Network and Security
- **Boot Method:** Legacy BIOS (MBR)
- **Data Storage:** `/mnt/scratch` is mounted automatically.
- **Management IP:** `10.0.0.2` (WireGuard)
- **Application IP:** `10.0.1.2`
- **SSH Access Restriction:** For enhanced security, SSH access is limited to the WireGuard (`wg0`) interface.

## Notes
- **GPU:** The GeForce 8400 GS is extremely old and modern NVIDIA drivers will not work. It runs on the open-source `nouveau` driver or standard kernel drivers.
