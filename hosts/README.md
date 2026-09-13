# hosts/ — Host-specific configuration & adding a new host

Each subdirectory is one machine. Hosts are registered in `flake/hosts.nix`
via `mkLib.mkSystem` (see `lib/`); the host entry itself lives in
`hosts/<name>/default.nix`. A ready-made skeleton lives in
[`hosts/_template/`](_template) — copy it when adding a machine.

Typical layout:

```text
hosts/<name>/
├── default.nix     # imports hardware.nix + services + ../../nixos; host overrides
├── hardware.nix    # fileSystems / swapDevices (storage only)
├── services/
│   ├── default.nix # imports this host's services
│   └── nebula.nix  # Nebula mesh membership (IP, groups)
└── README.md       # machine-specific docs (hardware, role, install steps)
```

## Adding a new host

Every host in this fleet uses **SOPS** (encrypted secrets) and **Nebula**
(mesh VPN), so both must be provisioned alongside the NixOS configuration.
The steps below cover the full path from skeleton to merged PR.

### 1. Branch

Use `feat/add-<hostname>` (or `fix/…`, `chore/…`, `docs/…`) as the branch
name. Branch, commit, push, PR, and merge follow the standard workflow in
`AGENTS.md` / `.codewhale/skills/dev-workflow/`.

### 2. Skeleton

```bash
cp -r hosts/_template hosts/<hostname>
```

Replace the `HOSTNAME` placeholders and fill in:

- `default.nix` — hostname, role-specific `my.*` flags, overrides
  (evaluation order: `profile → hosts/<name> → extraModules`, later wins).
- `hardware.nix` — `fileSystems` / `swapDevices`. Bootstrap with
  `nixos-generate-config --root /mnt --dir /tmp/nixos`, then switch device
  paths to stable `by-id` names.
- `services/nebula.nix` — next free IP `10.0.0.X` and groups (see the
  comments in the template for the allocation table).
- `README.md` — hardware headline, role, deployment commands.

Keep `imports = [ ./hardware.nix ./services ../../nixos ];` as-is.
Set `networking.hostName` — `my.hostKey` (the SOPS secret prefix) is derived
from it automatically (`nixos/base/user.nix`).

### 3. Register the host

Add an entry to `flake/hosts.nix`:

```nix
"<hostname>" = mkLib.mkSystem {
  name = "<hostname>";
  username = "t3u";
  system = "x86_64-linux";        # or aarch64-linux
  profile = "tower-server";       # desktop | tower-server | gateway | sbc
};
```

`extraModules` is for installer/failover variants (see `mkToriiChan`).
Optionally import a `nixos-hardware` profile in `default.nix` via
`inputs.nixos-hardware.nixosModules.<model>`.

### 4. SOPS — register the host key

The host decrypts its secrets with an age key derived from its SSH host key.

```bash
# on the new host (or from the generated host key):
ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub
# -> age1...
```

`.sops.yaml` is a plain (non-encrypted) config file, so edit it directly (its
`keys` / `creation_rules` cannot be managed by the `sops` CLI); keep the change
under review. The encrypted `secrets/*.yaml` data files are edited only with the
`sops` CLI:

1. Add `&<hostname>  age1...` to `keys:`.
2. Add a creation rule for `secrets/hosts/<hostname>.yaml`
   (`key_groups: [*master_key, *<hostname>]`).
3. Append `*<hostname>` to the `common.yaml` rule (CA secret is shared).

Create the host secret file (password hashes):
`mkpasswd -m sha-512` (or `nix shell nixpkgs#mkpasswd -c mkpasswd -m sha-512`):

```bash
sops set secrets/hosts/<hostname>.yaml '["<hostkey>_t3u_password_hash"]' '"<hash>"'
sops set secrets/hosts/<hostname>.yaml '["<hostkey>_root_password_hash"]' '"<hash>"'
```

Re-encrypt for the new key set:

```bash
sops updatekeys secrets/hosts/<hostname>.yaml secrets/common.yaml
```

(`<hostkey>` = hostname with `-` → `_`, e.g. `shosoin-tan` → `shosoin_tan`.)

### 5. Nebula — sign a node cert and import it

The CA lives on the operator side (`~/.nebula-ca`). Sign one node against the
**existing** CA (use `scripts/nebula-rotate-ca.sh` only for full CA rotation):

```bash
nix shell nixpkgs#nebula -c nebula-cert sign \
  -name "<hostname>" \
  -networks "10.0.0.<octet>/24" \
  -groups "mgmt" \
  -ca-crt ~/.nebula-ca/ca.crt \
  -ca-key ~/.nebula-ca/ca.key \
  -out-crt ~/.nebula-ca/<hostname>.crt \
  -out-key ~/.nebula-ca/<hostname>.key
```

If the CA key is passphrase-encrypted, feed the passphrase on a pty like
`run_nebula` in `scripts/nebula-rotate-ca.sh` does.

Then add the host to the `FLEET` array in `scripts/nebula-lib.sh`
(`<name>|<last-octet>|<groups>` — the single source of truth for both
`nebula-import-secrets.sh` and `nebula-rotate-ca.sh`; the secrets file path
and SOPS key prefix are derived from the name) and import — requires the
offline **master age key**:

```bash
SOPS_AGE_KEY_FILE=/path/to/master-age-key.txt bash scripts/nebula-import-secrets.sh
```

Verify: `sops --decrypt secrets/hosts/<hostname>.yaml | grep <hostkey>_nebula`

### 6. Validate

```bash
nix flake check
sudo nixos-rebuild dry-activate --flake .#<hostname>
```

### 7. Deploy

- **Clean install** — boot the NixOS installer, partition per `hardware.nix`,
  place the age key at `/mnt/var/lib/sops-nix/key.txt` (see the BrokenPC
  README for the canonical walkthrough), then:
  ```bash
  sudo NIXPKGS_ALLOW_UNFREE=1 nixos-install --flake .#<hostname>
  ```
- **Existing NixOS** — switch directly. Via Nebula once step 5 is done:
  ```bash
  nixos-rebuild switch --flake .#<hostname> --target-host t3u@10.0.0.<octet> \
    --sudo --ask-sudo-password
  ```

### 8. Commit & PR

Commit, push, PR via `gh` (body via `--body-file`), CI check, merge, and
main sync follow the standard workflow — see `AGENTS.md` /
`.codewhale/skills/dev-workflow/`.

## Notes

- **Keep secrets out of the repo**: only `sops`-encrypted values in
  `secrets/`, never plaintext. See `secrets/README.md` for the key model and
  recovery procedure.
- **Nebula IPs** are stamped into the signed certificates — changing an IP
  means re-signing (and re-importing) that node's cert.
- TLP vs `power-profiles-daemon`: `common-pc-laptop` (nixos-hardware)
  auto-enables TLP only when power-profiles-daemon is off.

## Nebula CA maintenance

- **CA validity**: 10y (rotated 2026-08-31; valid until **2036-08-28**). Node
  certificates are signed for **1y**, so refresh them yearly (next:
  2027-08-31) — this is a **re-sign, not a rotation**: `nebula-cert sign`
  against the existing CA, re-import into SOPS, deploy, `switch`.
- **Backup**: back up `~/.nebula-ca/{ca.crt,ca.key,passphrase}` (the CA key needs
  its passphrase to be useful). Node keys are recoverable from SOPS
  (`secrets/`), so they need no separate backup.