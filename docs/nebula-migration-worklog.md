# Nebula Mesh VPN — Migration Worklog (2026-08-10)

Operational log for the WireGuard → Nebula (full mesh) migration, per
`docs/plans/nebula-migration.md`. Single overlay `nebula0` (10.0.2.0/24),
UDP 4242, torii-chan = Lighthouse + Relay.

## Status

- **Phase 1 (parallel overlay)**: deployed on **torii-chan** (Lighthouse/Relay)
  and **BrokenPC** (client). WireGuard (wg0/wg1) intentionally kept active.
- **torii-chan HDD migration**: completed (root now on HDD, HDD services active).
- **Phase 2 smoke checks**: P2P + nebula SSH verified between BrokenPC ↔ torii-chan.
- **Phase 3 (full migration)**: WireGuard removed on **torii-chan** and **BrokenPC**
  (applied via nebula-only SSH; nebula0 is now the only tunnel on those hosts).
- **Pending**: 3 hosts (shosoin-tan / kagutsuchi-sama / sando-kun) are OFFLINE;
  apply the Phase-3 config (they already carry the nebula secrets) when they come
  online. Minecraft / DNAT / restic / Relay checks need shosoin-tan online.

## What was done

### 1. Common module `nixos/networking/nebula.nix`
- Generates `services.nebula.networks.nebula0` from `my.networking.nebula`
  (ip / groups / mtu / isLighthouse / isRelay / extraInbound).
- SOPS-declared CA cert (`secrets/common.yaml`) + per-host node cert/key
  (`secrets/hosts/<host>.yaml`).
- `tun.device = nebula0`, `networking.firewall.trustedInterfaces = [ "nebula0" ]`
  (in-tunnel control delegated to the Nebula firewall: ICMP + extraInbound only).
- MTU 1320 (common). Relay = torii-chan. Lighthouse advertised via
  `advertise_addrs = torii-chan.t3u.uk:4242` (SBC/VPS DDNS failover).
- Imported in `nixos/networking/default.nix`.

### 2. Host wiring (WireGuard kept)
- torii-chan (gateway profile, shared by SBC+VPS): Lighthouse + Relay @ 10.0.2.1,
  inbound 22 (mgmt) + 25565 (app).
- shosoin-tan 10.0.2.4 (mgmt,app): inbound 22 (mgmt) + 25565 (from 10.0.2.1).
- kagutsuchi-sama 10.0.2.3 (mgmt): inbound 22.
- sando-kun 10.0.2.2 (mgmt): inbound 22.
- BrokenPC 10.0.2.100 (mgmt,app): ICMP only (no services).

### 3. CA + certificates
- CA `t3u-home-ca` created in `~/.nebula-ca/` (10-year, networks 10.0.2.0/24,
  groups mgmt,app, **passphrase-encrypted**). Passphrase in
  `~/.nebula-ca/passphrase` (0600) — store in a password manager.
- 5 node certs (1-year, `10.0.2.x/24`) issued via `nebula-cert sign`.
- Verified with `nebula-cert print` (name / networks / groups / validity).

### 4. SOPS secrets
- CA cert → `secrets/common.yaml` (`nebula_ca`).
- Node cert/key → each `secrets/hosts/<host>.yaml` via
  `scripts/nebula-import-secrets.sh` (requires the offline master key).
- **Fix**: common.yaml still carried the pre-2026-08 torii-chan age key; ran
  `sops updatekeys` so the gateway can decrypt the shared CA cert.

### 5. Deployments
- torii-chan: `nixos-rebuild switch --flake .#torii-chan-hdd --target-host ...`
  (with `--sudo --ask-sudo-password`). Lighthouse now active (10.0.2.1/4242).
- BrokenPC: `sudo nixos-rebuild switch --flake .#BrokenPC` — client active
  (10.0.2.100).

### 6. torii-chan HDD migration (root from SD → HDD)
- Formatted `/dev/sda1` as ext4 with label `NIXOS_HDD` (`mkfs.ext4 -L NIXOS_HDD`).
- rsync'd `/` to the HDD (excluded virtual/boot-only mounts; `/boot` stays on SD).
- Verified system profile link + fstab, then rebooted.
- After boot: root on `/dev/sda1`, `hdd-apm.service` + `smartd.service` active.
- Procedure documented in `hosts/torii-chan/README.md` (Phase 3).

### 7. Phase 3 — full migration (remove WireGuard)
- gateway: dropped `wg0`/`wg1` (interfaces, ports 51820/51821, keys, firewall
  rules); NAT/MASQUERADE now forwards 25565 → `10.0.2.4`; `internalInterfaces`
  emptied (mesh is P2P, no outbound overlay NAT).
- `tower-server/security.nix`: SSH now only via nebula0 (dropped the wg0 firewall
  reference); `allowedTCPPorts = mkForce []` still holds.
- Deleted all host `wireguard.nix` files + `nixos/networking/wireguard.nix` +
  their imports.
- `shosoin-tan` restic backup: remote receiver `10.0.1.3` → `10.0.2.3` (nebula).
- **Applied on torii-chan and BrokenPC** (via nebula-only SSH). After apply:
  `wg0`/`wg1` gone, nebula0 is the only tunnel, P2P ping + SSH over mesh OK.
- 3 offline hosts still need the Phase-3 config applied when online.

## Verification (Phase 2, partial)

- **P2P**: `ping 10.0.2.1` from BrokenPC → 0% loss (rtt 5–33 ms).
- **SSH over mesh**: `ssh t3u@10.0.2.1` from BrokenPC succeeds.
- Remaining (needs shosoin-tan online): Minecraft within mesh, DNAT return,
  restic SFTP, mobile (NAT64) P2P/Relay fallback.

## Issues found & fixed during rollout

1. **ICMP inbound rule** — Nebula ≥1.10 requires host/group/cidr on every
   inbound rule; bare `{proto=icmp; port=any}` made nebula exit 1. Fixed with
   `host = "any"`. (`78164bd`)
2. **static_host_map** — clients need the Lighthouse's real address; without it
   nebula exits 1 ("lighthouse ... does not have a static_host_map entry").
   Added `staticHostMap` on non-lighthouse nodes. (`54b7ecc`)
3. **common.yaml stale torii-chan key** — fixed via `sops updatekeys`. (`ccc1b95`)

## Subnet change: 10.0.2.0/24 → 10.0.0.0/24 (2026-08-10)

Overlay subnet rotated to **10.0.0.0/24** (same band as the retired WireGuard
`wg0` management net, so it aligns with `home/programs/ssh.nix` host entries).

- **Why**: during the design the overlay used `10.0.2.0/24`; aligning on
  `10.0.0.0/24` keeps a single management band across the fleet and matches the
  SSH host definitions (`10.0.0.1`–`10.0.0.100`).
- **New tool** `scripts/nebula-rotate-ca.sh`: one-shot CA rotation (new CA for
  `10.0.0.0/24` + re-sign all 5 nodes), feeding the encrypt passphrase on a pty.
  Reuses `scripts/nebula-import-secrets.sh` for the SOPS step.
- **Certificates**: new CA `t3u-home-ca` (networks `10.0.0.0/24`, groups
  `mgmt,app`) written to `~/.nebula-ca-10-0-0/`; all node certs re-signed to
  `10.0.0.x/24` (verified via `nebula-cert print`).
- **SOPS**: `secrets/common.yaml` (`nebula_ca`) + all `secrets/hosts/*.yaml`
  (`*_nebula_cert` / `*_nebula_key`) re-encrypted via
  `nebula-import-secrets.sh` (master key).
- **Config**: `nixos/networking/nebula.nix`, `nixos/profiles/gateway/default.nix`,
  `hosts/*/services/nebula.nix`, `hosts/shosoin-tan/services/backup.nix` updated
  to `10.0.0.x`.
- **Verified**: `nix flake check` passes.

## Remaining / Next steps

- **Deploy 3 offline hosts** with the Phase-3 config when they come online:
  `sudo nixos-rebuild switch --flake .#<host>`
  (shosoin-tan / kagutsuchi-sama / sando-kun). They already carry the nebula
  secrets, so a plain switch is enough.
- **Phase 2 residual checks** (need shosoin-tan online): Minecraft within mesh,
  DNAT return (25565 → 10.0.2.4), restic SFTP (→ 10.0.2.3), mobile (NAT64)
  P2P / Relay fallback.
- **Phase 4 ops**: cert rotation (1y), `pki.blocklist` maintenance, optional 2nd
  Lighthouse.

## Relevant commits (branch `docs/nebula-mesh-design`)

- `cb49adb` feat(networking): remove WireGuard, migrate fully to the Nebula mesh
- `c932850` docs(nebula): add migration worklog
- `c0c60ec` docs(torii-chan): detail the HDD migration procedure in README
- `54b7ecc` fix(nebula): add static_host_map for clients to reach the Lighthouse
- `78164bd` fix(nebula): add host=any to the common inbound ICMP rule
- `ccc1b95` fix(secrets): update common.yaml recipients to the torii-chan key
- `137a479` chore(secrets): add Nebula CA cert and per-host node certs/keys
- `d6bc353` feat(networking): add Nebula mesh VPN (nebula0) config