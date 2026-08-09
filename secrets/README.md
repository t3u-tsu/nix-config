# secrets/ — SOPS-encrypted secrets

This directory holds all encrypted secrets for the fleet. Files are
encrypted with [SOPS](https://github.com/getsops/sops) using
[age](https://age-encryption.org/) keys. Do **not** commit plaintext secrets.

## Layout

- `hosts/<hostname>.yaml` — host-specific secrets (password hashes,
  WireGuard private keys, ...).
- `services/<service>.yaml` — service-level secrets shared by the hosts that
  run the service (DDNS, Minecraft, backup, signing, ...).
- `common.yaml` — secrets shared across every host.

## Key model (`.sops.yaml`)

Each secret file is encrypted for a **key group**:

- **master_key** — offline recovery key (password manager / offline storage).
  It is included in the key group of every host file so any secret can be
  decrypted even when the host's own key is unavailable.
- **host key** — per-host age key derived from the SSH host key
  (`ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub`). This is what the host
  uses to decrypt its secrets at boot.
- **user_t3u** — operator key on the daily workstation. Deliberately
  **excluded** from host files (maximum isolation); it is only in service /
  common files that the operator must edit directly.

### Why master_key is included in host files

If a host's SSH host key is lost (e.g. SD card replaced), the secrets are
**still recoverable with master_key**:

1. Decrypt the host's secrets with master_key.
2. Register the new host key (derived from the new SSH host key) in
   `.sops.yaml`.
3. `sops updatekeys` on the affected files.
4. Commit and re-deploy.

So host keys never need to be backed up for recoverability — master_key is
the single recovery authority (keep it safe and offline!).

## Workflow

### Edit a secret

```bash
sops secrets/hosts/torii-chan.yaml
# or any file under secrets/
```

### Add a new host

1. Boot the host and derive its age key from its SSH host key:
   ```bash
   ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub
   ```
2. Add the derived key to `.sops.yaml` as `&<hostname>` (and `&<hostname>_vps`
   for failover hosts) and include it in the key groups of the files the host
   needs (`secrets/hosts/<hostname>.yaml`, relevant `secrets/services/*.yaml`).
3. Re-encrypt with the new key:
   ```bash
   sops updatekeys secrets/hosts/<hostname>.yaml secrets/services/<service>.yaml
   ```
4. Commit and deploy.

### Recover after a lost host key

See [Why master_key is included in host files](#why-master_key-is-included-in-host-files).
Use the master_key private key file via `SOPS_AGE_KEY_FILE`:

```bash
SOPS_AGE_KEY_FILE=/path/to/master-key sops -d secrets/hosts/<hostname>.yaml   # verify
SOPS_AGE_KEY_FILE=/path/to/master-key sops updatekeys secrets/hosts/<hostname>.yaml
```

## Operational notes

- **master_key private key**: keep OFFLINE (password manager). Never commit
  it or copy it into the repo.
- **SSH host keys** are generated fresh on every flashed image. At boot,
  the `0-sops-key-import` activation script (see `nixos/security/sops.nix`)
  derives `/var/lib/sops-nix/key.txt` from the SSH host key automatically,
  so sops decryption just works on new images once the new key is registered
  in `.sops.yaml`.
- Keep `sops.age.generateKey = false`: enabling it would create a **random**
  age key (`age-keygen`) that cannot decrypt host-key-encrypted secrets.
- After adding/removing keys, verify the affected files still decrypt:
  `sops updatekeys` runs the same key-derivation as the boot path.
