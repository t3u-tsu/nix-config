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
- **`vps.nix`** (failover VPS, ConoHa): static networking from the ConoHa panel
  (`eth0`), GRUB to the MBR of the VirtIO disk (`/dev/vda`), operator pubkey.
  Replace the `192.0.2.x` TEST-NET placeholders (`wanIp`/`wanGateway`) with the panel values before deploying.

## Configurations in Flake

- `torii-chan-sd`: initial SD card image build.
- `torii-chan-sd-live`: update system while running on SD card.
- `torii-chan`: production on the physical SBC (root on HDD).
- `torii-chan-vps`: same role on a failover VPS (x86_64).
- `torii-chan-vps-installer`: SSH-operable NixOS installer ISO for the VPS (x86_64).

## VPS Failover
> **⚠️ NOT VERIFIED**: The VPS failover path (`vps.nix`, installer ISO, DDNS
> takeover) has NOT been tested on a real VPS yet. The static
> IP/gateway in `vps.nix` are TEST-NET placeholders (`192.0.2.x`) and must be
> replaced with real ConoHa panel values before any deployment.

Because peers always connect to the public hostname `torii-chan.t3u.uk`, takeover
is seamless: when the VPS assumes the role, its own DDNS updates the A record
(IPv4-only; ip6Domains is empty) to the VPS public IP and all peers reconnect automatically.

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
4. Deploy `.#torii-chan-vps`. (Auto-deployment via comin was dropped; a deploy-rs
   migration is planned as a separate task so the VPS can track `main`.)

### Before activating the VPS

- Verify the firewall: public SSH is intentionally restricted to `wg0`. For the
  FIRST deploy you must bring the VPS up while it can still be reached over
  `wg0` (connect from a peer), or temporarily open port 22 on the WAN.
- Ensure `mc.t3u.uk`, `*.mc.t3u.uk`, and `torii-chan.t3u.uk` are served by the
  active gateway (its DDNS handles this; only one gateway runs at a time).


## Setup Guide (VPS / ConoHa)

Target: ConoHa VPS (GMO), cheapest plan (512 MB, 1 vCPU / 30 GB SSD, ~460円/月
with the まとめトク discount), hourly billing (1-hour units), Tokyo region.

### Phase 1: Create the VPS
1. Create the VPS in **tyo1 or tyo2**. (The custom-ISO API is NOT supported in
   tyo3; the ISO mount flow below requires tyo1/tyo2.)
2. Note the STATIC IPv4 / netmask / gateway shown in the panel — ConoHa does
   NOT serve DHCP; these values go into `hosts/torii-chan/vps.nix`
   (`wanIp` / `wanGateway`, currently `192.0.2.x` TEST-NET placeholders).
3. **Security groups**: ConoHa v3 security groups default to DENY-ALL at the
   hypervisor level. Allow at minimum: TCP 22 and 25565, UDP 51820 and 51821
   (plus TCP 22 for bootstrap).

### Phase 2: Boot the NixOS installer from a custom ISO
Instead of the stock minimal ISO, you can build the SSH-operable custom ISO
from this repo (`hosts/torii-chan/vps-installer.nix`):

```bash
nix build .#torii-chan-vps-iso -o result-iso
ls result-iso/iso/   # nixos-<version>-x86_64-linux.iso
```

The custom ISO has sshd enabled with the operator pubkey, static IP support
(via `conoha.installer.wan`), and the `install-nixos` helper script, so no VNC
console work is needed. (Static IP must be baked in before building, or set
manually at boot with `install-nixos.sh network`.)
The live environment deliberately does NOT contain the production (SOPS-managed)
password hashes. Two build options:

- `nix build .#torii-chan-vps-iso -o result-iso` — no password set (SSH key
  login only; recommended unless you need the VNC console).
- `./hosts/torii-chan/build-vps-iso.sh` — auto-generates a throwaway password,
  bakes its hash into the ISO (`--impure` build), and saves the password to
  `result-iso-temp-password.txt` (mode 0600). Use this only when console login
  on the VNC console is needed.

After installation, deploy the real config (`nixos-rebuild switch --flake
.#torii-chan-vps`) and the system switches to the SOPS-managed password.

1. Host the NixOS minimal ISO at a public URL (ConoHa downloads the ISO itself
   from an external URL — there is no panel upload):
   e.g. `https://channels.nixos.org/nixos-26.05/latest-nixos-minimal-x86_64-linux.iso`
2. Use the `conoha-iso` CLI (https://github.com/hironobu-s/conoha-iso):
   ```bash
   conoha-iso download <ISO_URL>      # ConoHa stores it in a temp area
   conoha-iso list                    # find the ISO id
   # STOP the VPS first, then insert the ISO and start it:
   conoha-iso insert <VPS_ID> <ISO_ID>
   ```
   Boot into the installer via the panel console (separate browser window;
   it has a text-send feature but no copy-paste).
3. Partition the VirtIO disk (BIOS/SeaBIOS, MBR) and mount:
   ```bash
   parted /dev/vda -- mklabel msdos mkpart primary ext4 1MiB 100%
   mkfs.ext4 -L nixos /dev/vda1
   mount /dev/vda1 /mnt
   ```
4. Install NixOS with a minimal configuration that:
   - sets the STATIC network from the panel (`eth0`, IP/netmask/gateway) —
     also set `networking.usePredictableInterfaceNames = false` so the NIC
     really is `eth0`,
   - writes GRUB to the MBR: `boot.loader.grub.device = "/dev/vda";`,
   - keeps SSH reachable on the WAN for bootstrap
     (`my.services.gateway.restrictAccess = lib.mkForce false;`).
   After `nixos-install`, eject the ISO (`conoha-iso eject <VPS_ID> <ISO_ID>`)
   and reboot.
5. Alternative path (community-proven): boot the `nixos-kexec-installer` from a
   running Ubuntu, then `nixos-anywhere --phases install` with a GPT layout
   (BIOS-boot ef02 + root). See
   https://gist.github.com/HelloWorld017/13e9aa366de60f3d9ecfc605e607b8d0

### Phase 3: SOPS + first deploy
1. Complete the SOPS prerequisites above (add the VPS age key derived from its
   SSH host key; `sops updatekeys`).
2. Fill in `hosts/torii-chan/vps.nix`: `wanIp`/`wanGateway` from the panel.
3. Deploy:
   ```bash
   nixos-rebuild switch --flake .#torii-chan-vps --target-host root@<VPS_IP> --use-remote-sudo --ask-sudo-password
   ```
4. After the first boot, re-enable SSH hardening by removing the temporary
   `restrictAccess = lib.mkForce false;` from the bootstrap config and redeploy.

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
4GB swapfile at `/var/lib/swapfile`, `vm.swappiness = 10` (SBC profile). The VPS
(`vps.nix`) mirrors this on the 512MB plan: same swapfile + swappiness, with the
bootstrap keeping a single root partition `/dev/vda1` (NixOS creates the
swapfile at boot).

### USB HDD Stability
`usb-storage.quirks=152d:0583:u` disables UAS for the JMicron JMS583 bridge.

### Firewall Log Suppression
`logRefusedConnections = false` suppresses noise on this internet-exposed host.
