# Host: shosoin-tan (i7-870 Tower Server)

This host is a tower server equipped with an Intel Core i7-870 and a ZFS Mirror configuration, used for data storage and general-purpose services.

## Hardware Specs
- **CPU:** Intel Core i7-870 (1st Gen)
- **GPU:** Quadro K2200 (Maxwell)
- **RAM:** 16GB
- **Storage:**
  - 480GB SSD (OS / Boot)
  - 1TB HDD x2 (ZFS Mirror: `tank-1tb`)
  - 320GB HDD x2 (ZFS Mirror: `tank-320gb`)

## 🚀 Installation Guide

Due to older hardware and high build loads, this host uses a specific remote-build installation procedure for stability.

### Phase 1: Disk Preparation
1. **Run Disko:** Execute from another Linux machine.
   ```bash
   nix build .#nixosConfigurations.shosoin-tan.config.system.build.diskoScript
   nix copy --to ssh://nixos@<IP> ./result
   ssh -t nixos@<IP> "sudo ./result --mode destroy,format,mount"
   ```

### Phase 2: Transfer Secret Key
```bash
ssh nixos@<IP> "sudo mkdir -p /mnt/var/lib/sops-nix"
cat ~/.config/sops/age/keys.txt | ssh nixos@<IP> "sudo tee /mnt/var/lib/sops-nix/key.txt > /dev/null"
```

### Phase 3: Build and Transfer System (Recommended)
To avoid CPU freezes on the target, build the image on a build host and transfer it.
1. **Build:** `nix build .#nixosConfigurations.shosoin-tan.config.system.build.toplevel`
2. **Transfer:** `nix copy --to ssh://nixos@<IP> ./result`
3. **Install:** `ssh nixos@<IP> "sudo nixos-install --system $(readlink -f ./result)"`

## 🔐 Network and Security
- **Boot Method:** Legacy BIOS (MBR)
- **Management IP:** `10.0.0.4` (WireGuard)
- **SSH Access Control:** Limited to the WireGuard (`wg0`) interface for enhanced security.

## ⚠️ Notes
- **Overclocking:** CPU overclocking can cause instability (Kernel Oops) during heavy Nix builds. Running at stock speeds is highly recommended.
- **resolv.conf:** If networking services fail due to signature mismatch after installation, manually delete `/etc/resolv.conf` and restart.