# Host: torii-chan (Orange Pi Zero3)

This directory contains the NixOS configuration for `torii-chan`, an Orange Pi Zero3 node used as a WireGuard server and DDNS client.

## Hardware Specs
- **Model:** Orange Pi Zero3 (Allwinner H618)
- **Architecture:** aarch64-linux

## Configurations in Flake
- `torii-chan-sd`: Initial SD card image build.
- `torii-chan-sd-live`: Update system while running on SD card.
- `torii-chan`: Production configuration with root on HDD.

---

## 🚀 Setup Guide

### Phase 1: Build & Flash SD Image
1. **Build the SD Image:**
   ```bash
   nix build .#nixosConfigurations.torii-chan-sd.config.system.build.sdImage
   ```
2. **Flash to SD Card:**
   ```bash
   sudo dd if=result/sd-image/nixos-image-sd-card-*.img of=/dev/sdX bs=4M status=progress conv=fsync
   ```

### Phase 2: Initial Provisioning
1. **Insert Key:** Place your age secret key at `/var/lib/sops-nix/key.txt`.
2. **First Deploy:**
   ```bash
   nix run nixpkgs#nixos-rebuild -- switch --flake .#torii-chan-sd-live --target-host root@192.168.0.128
   ```

### Phase 3: Migrate to HDD (Completed ✅)
1. **Prepare HDD:** Format with label `NIXOS_HDD`.
2. **Copy Data:** Rsync `/` to the HDD partition.
3. **Switch Config:**
   ```bash
   nix run nixpkgs#nixos-rebuild -- switch --flake .#torii-chan --target-host t3u@10.0.0.1 --sudo
   ```   *System now boots from HDD with /boot on SD card.*

## 🔐 Services and Secrets
- **Update Hub:** Coordinated Update Hub managing the fleet update status. Provides status at 10.0.1.1:8080.
- **WireGuard:** VPN Server (10.0.0.1).
- **DDNS:** Cloudflare DDNS (favonia). Requires API Token. Manages `torii-chan.t3u.uk` and Minecraft domains `mc.t3u.uk`, `*.mc.t3u.uk`.
- **Secrets:** Managed via `sops-nix`. Edit with `sops secrets/secrets.yaml`.

## 🛠️ Operation & Troubleshooting

### Remote Deployment Build Errors (seccomp / sandbox)
Custom or legacy kernels (like those on Orange Pi) often lack support for modern Linux kernel security features (`user_namespaces`, `seccomp BPF`) required by the Nix daemon.
As a result, regular remote deployments will silently freeze or crash with outputs like `error: unable to load seccomp BPF program`.
To bypass this limitation and successfully evaluate and apply configurations directly natively on `torii-chan`, use the following syntax (run as a regular user since running `sudo nixos-rebuild` externally breaks SSH key agent forwarding):

```bash
nixos-rebuild switch --flake .#torii-chan --target-host t3u@10.0.0.1 --use-remote-sudo --ask-sudo-password --option sandbox false --option filter-syscalls false
```
*Note: While `nix.settings.sandbox = false;` is declared in `configuration.nix`, appending these explicit option flags during manual invocation guarantees evasion.*

### Unstable SSH Connection or Timeout
Due to the resource constraints of the Orange Pi, key exchange may timeout. Use the `curve25519-sha256` algorithm explicitly or ensure it's enforced in the configuration.

```bash
# Example for manual connection
ssh -o KexAlgorithms=curve25519-sha256 t3u@10.0.0.1
```

### Network (WireGuard) Stability
When using unstable parent connections like Rakuten Mobile (MTU 1340), packet fragmentation can cause hangs. The MTU for `wg0` and `wg1` is set to `1300` for better stability.

### Out-of-Memory (OOM) Issues
Builds may fail with `Result: oom-kill` due to low RAM.
A permanent 4GB swap file at `/var/lib/swapfile` is configured, with `vm.swappiness = 10` for optimization.

### USB HDD Stability (UAS Compatibility Fix)
To avoid UAS (USB Attached SCSI) compatibility issues with the JMicron JMS583 bridge (`152d:0583`), the system is configured with kernel param `usb-storage.quirks=152d:0583:u` to disable UAS and force the stable `usb-storage` driver.

### Firewall Log Suppression
Since this node is exposed to the internet, `logRefusedConnections = false` is set to suppress noisy kernel logs from blocked scan attempts.

### Auto-Update (Update Hub) Sync Failure
If the commit notified by the Hub is not found locally, sync the repository manually:
```bash
cd ~/nix-config
git fetch --all
git reset --hard origin/main
```
After syncing, trigger the update manually via the webhook port:
```bash
curl -X POST http://127.0.0.1:8081/trigger-update
```
