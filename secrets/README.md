# secrets/ — SOPS-encrypted secrets

Encrypted with [SOPS](https://github.com/getsops/sops) using
[age](https://age-encryption.org/) keys. Never commit plaintext secrets.

## Layout

- `hosts/<hostname>.yaml` — host-specific secrets (password hashes, Nebula node
  certs/keys, ...).
- `services/<service>.yaml` — service-level secrets shared by the hosts that run
  the service (DDNS, Minecraft, backup, signing, ...).
- `common.yaml` — secrets shared by every host.

## Key model (`.sops.yaml`)

- **master_key** — offline recovery key (password manager / offline storage).
  Listed in the key group of every file, so any secret stays decryptable when a
  host key is unavailable.
- **host keys** — `torii_chan`, `shosoin_tan`, `kagutsuchi_sama`, `sando_kun`,
  `brokenpc`, `x1c7`. Derived from each SSH host key
  (`ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub`); a host uses its own key to
  decrypt its secrets at boot.
- **user keys** — `brokenpc_user` (`t3u@BrokenPC`) and `x1c7_user` (`x1c7`),
  derived from `~/.ssh/id_ed25519` on the desktop workstations. They are
  **excluded** from the host files and from `common.yaml`; only
  `services/signing.yaml` and `services/conoha-vps-mcp.yaml` list them.

Resulting key groups:

| File | Keys |
| --- | --- |
| `hosts/<hostname>.yaml` | master_key + that host's key |
| `common.yaml` | master_key + all six host keys |
| `services/minecraft.yaml`, `services/backup.yaml` | master_key + `shosoin_tan` |
| `services/ddns.yaml` | master_key + `torii_chan` |
| `services/signing.yaml`, `services/conoha-vps-mcp.yaml` | master_key + both user keys |

A lost host key is recoverable: decrypt with master_key, register the new key in
`.sops.yaml`, `sops updatekeys`, re-deploy. Host keys need no backup.

## Workflow

### Open a secret for editing

Host files exclude the user keys, so the default identity
(`~/.config/sops/age/keys.txt`) cannot decrypt them. Pass the master key:

```bash
SOPS_AGE_KEY_FILE=/path/to/master-key sops secrets/hosts/<hostname>.yaml
```

`services/signing.yaml` and `services/conoha-vps-mcp.yaml` open with the default
identity instead.

### Set a host password hash

`scripts/set-host-password.sh` prompts for the t3u and root passwords and writes
`<hostkey>_t3u_password_hash` / `<hostkey>_root_password_hash`. Pass the master
key when the file already exists (merging requires decrypting it first):

```bash
SOPS_AGE_KEY_FILE=/path/to/master-key \
  nix shell nixpkgs#mkpasswd nixpkgs#sops nixpkgs#jq -c bash scripts/set-host-password.sh <hostname>
```

### Add a new host

1. Boot the host and derive its age key from its SSH host key:
   ```bash
   ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub
   ```
2. Add the derived key to `.sops.yaml` as `&<hostname>` and list it in the key
   groups the host needs (`secrets/hosts/<hostname>.yaml`, relevant
   `secrets/services/*.yaml`).
3. Re-encrypt with the new key:
   ```bash
   SOPS_AGE_KEY_FILE=/path/to/master-key sops updatekeys secrets/hosts/<hostname>.yaml secrets/services/<service>.yaml
   ```
4. Commit and deploy.

Failover hosts run one machine at a time, but each still needs its own host key —
there is no shared `<hostname>_vps` entry. `torii-chan`'s VPS key is **not
provisioned yet**: the VPS would decrypt `secrets/hosts/torii-chan.yaml` and
`secrets/services/ddns.yaml` only once its SSH host key is added to both key
groups (see `hosts/torii-chan/vps.nix`).

## Operational notes

- Keep the master_key private key offline; never commit it.
- SSH host keys are regenerated on every flashed image. The `0-sops-key-import`
  script (`nixos/security/sops.nix`) derives `/var/lib/sops-nix/key.txt` at boot,
  so register the new key in `.sops.yaml` after flashing.
- Keep `sops.age.generateKey = false`; a random age key cannot decrypt
  host-key-encrypted secrets.
