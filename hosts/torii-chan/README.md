# Host: torii-chan (VPN Gateway / WireGuard Server + DDNS + Minecraft Forward)

This directory configures **torii-chan**, a VPN gateway that can run on EITHER
the physical Orange Pi Zero3 SBC **or** a VPS — one at a time (failover).
Both machines share the same hostname `torii-chan` and the SAME secrets
(WireGuard keys, DDNS token), so peers keep reaching the host at
`torii-chan.t3u.uk:51820/51821` without reconfiguration.

## Role (shared module)

The gateway role itself is platform-agnostic and lives in
`nixos/profiles/gateway/default.nix`:

- WireGuard servers: `wg0` management net `10.0.0.1/24`, `wg1` app net `10.0.1.1/24`
- NAT + port-forward `25565` → `shosoin-tan (10.0.1.4)` (Minecraft proxy)
- Cloudflare DDNS for `torii-chan.t3u.uk`, `mc.t3u.uk`, `*.mc.t3u.uk`
- Firewall hardening: SSH only via `wg0`, public `25565`, all of `wg1` trusted
- SOPS-managed WireGuard keys + Cloudflare token

Platform-specific wiring is split into two thin layers:

- **`sbc.nix`** (Orange Pi Zero3): extlinux boot chain, static LAN network on
  `end0` (192.168.0.128), and the low-RAM SBC profile (swapfile, sandbox off).
- **`vps.nix`** (failover VPS): DHCP networking, GRUB boot, comin + operator
  pubkey. **Adjust the `wanInterface` and GRUB `device` placeholders to your
  provider before deploying.**

## Configurations in Flake

- `torii-chan-sd`: initial SD card image build.
- `torii-chan-sd-live`: update system while running on SD card.
- `torii-chan`: production on the physical SBC (root on HDD).
- `torii-chan-vps`: same role on a failover VPS (x86_64).

## VPS Failover

Because peers always connect to the public hostname `torii-chan.t3u.uk`, takeover
is seamless: when the VPS assumes the role, its own DDNS updates the A/AAAA
record to the VPS public IP and all peers reconnect automatically.

### Prerequisites (SOPS)

Both machines decrypt the SAME files: `secrets/hosts/torii-chan.yaml` and
`secrets/services/ddns.yaml`. Before the VPS can boot with secrets it needs its
own age identity added to those files:

1. Provision the VPS and copy in the operator pubkey. Boot a minimal NixOS with
   SSH access from the control network (or via the provider console).
2. Derive the VPS age key from its SSH host key:
   `ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub`
3. Add that key to `.sops.yaml` as `&torii_chan_vps` and include it in the
   `secrets/hosts/torii-chan.yaml` and `secrets/services/ddns.yaml` key groups;
   then `sops updatekeys secrets/hosts/torii-chan.yaml` (and ddns.yaml) and
   commit.
4. Deploy `.#torii-chan-vps` and let comin track `main` (already enabled) so the
   VPS stays in sync with the fleet.

### Before activating the VPS

- Verify the firewall: public SSH is intentionally restricted to `wg0`. For the
  FIRST deploy you must bring the VPS up while it can still be reached over
  `wg0` (connect from a peer), or temporarily open port 22 on the WAN.
- Ensure `mc.t3u.uk`, `*.mc.t3u.uk`, and `torii-chan.t3u.uk` are served by the
  active gateway (its DDNS handles this; only one gateway runs at a time).

## Setup Guide (SBC)

### Phase 1: Build & Flash SD Image
```bash
nix build .#nixosConfigurations.torii-chan-sd.config.system.build.sdImage
sudo dd if=result/sd-image/nixos-image-sd-card-*.img of=/dev/sdX bs=4M status=progress conv=fsync
```

### Phase 2: Initial Provisioning
1. Place your age secret key at `/var/lib/sops-nix/key.txt`.
2. First deploy:
   ```bash
   nix run nixpkgs#nixos-rebuild -- switch --flake .#torii-chan-sd-live --target-host root@192.168.0.128
   ```

### Phase 3: Migrate to HDD
1. Format HDD with label `NIXOS_HDD`.
2. Rsync `/` to the HDD partition.
3. Switch config:
   ```bash
   nix run nixpkgs#nixos-rebuild -- switch --flake .#torii-chan --target-host t3u@10.0.0.1 --use-remote-sudo --ask-sudo-password
   ```

## Secrets

- WireGuard server keys + password hashes: `secrets/hosts/torii-chan.yaml`
- Cloudflare DDNS token: `secrets/services/ddns.yaml`

## Operation & Troubleshooting

### Remote Deployment Build Errors (seccomp / sandbox)
The Orange Pi kernel lacks `user_namespaces` / `seccomp BPF`. Deploy natively:
```bash
nixos-rebuild switch --flake .#torii-chan --target-host t3u@10.0.0.1 --use-remote-sudo --ask-sudo-password --option sandbox false --option filter-syscalls false
```

### Unstable SSH Connection or Timeout
```bash
ssh -o KexAlgorithms=curve25519-sha256 t3u@10.0.0.1
```

### Network (WireGuard) Stability
Unstable parent links (Rakuten Mobile MTU 1340) → `wg0`/`wg1` MTU is 1300.

### Out-of-Memory (OOM)
4GB swapfile at `/var/lib/swapfile`, `vm.swappiness = 10` (SBC profile).

### USB HDD Stability
`usb-storage.quirks=152d:0583:u` disables UAS for the JMicron JMS583 bridge.

### Firewall Log Suppression
`logRefusedConnections = false` suppresses noise on this internet-exposed host.
