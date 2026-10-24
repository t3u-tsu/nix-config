# Operational Scripts (`scripts/`)

Operator maintenance scripts for fleet management, credential provisioning, and certificate rotation, plus markdown validation scripts run by pre-commit.

## Scripts Overview

| Script | Purpose | Prerequisites |
| :--- | :--- | :--- |
| [secret.ysh](secret.ysh) | Unified CLI for manifest-driven migration, rekey, editing, staged imports, and environment checks. | `bw`, `sops`, `age`, `agenix` |
| [agenix-bw-lib.ysh](agenix-bw-lib.ysh) | Shared Bitwarden session handling and master-identity extraction used by `secret.ysh` and the agenix wrappers. | `bw` |
| [agenix-with-bw.ysh](agenix-with-bw.ysh) | Runs an arbitrary `agenix` command with the Bitwarden master identity. | `bw`, `agenix` |
| [migrate-sops-to-agenix.ysh](migrate-sops-to-agenix.ysh) | Compatibility wrapper for `secret.ysh migrate`; delegates to [the manifest](../secrets/migration-manifest.json). | `bw`, `sops`, `age` |
| [nebula-lib.ysh](nebula-lib.ysh) | Shared fleet registry defining `FLEET` node mappings (`name\|last-octet\|groups`) and path helpers. | Sourced by Nebula scripts |
| [nebula-import-secrets.ysh](nebula-import-secrets.ysh) | Imports Nebula CA and host certs/keys into SOPS host files. | `SOPS_AGE_KEY_FILE` (Master key) |
| [nebula-rotate-ca.ysh](nebula-rotate-ca.ysh) | One-shot Nebula CA recreation and bulk node re-signing. | `nebula-cert` on PATH |
| [set-host-password.ysh](set-host-password.ysh) | Hashes user/root passwords (`mkpasswd`) and injects hashes into `secrets/hosts/<hostname>.yaml`. | `mkpasswd`, `sops`, `SOPS_AGE_KEY_FILE` |
| [check-docs.pl](check-docs.pl) | Lints markdown prose (parentheses, commas, prohibited words, pseudo-headings) and validates relative links and heading anchors. | Perl core (run via pre-commit) |
| [linkify-markdown.pl](linkify-markdown.pl) | Scans markdown files and converts raw in-text file paths into relative links. | Perl core |
| [restart-touchpad.ysh](restart-touchpad.ysh) | Recovers and rebinds the AMD I2C controller and Synaptics touchpad on HP Victus 16. | `ysh`, `pkexec` |

## Secret CLI

`secret.ysh` wraps the Bitwarden master identity and the agenix-rekey commands. An empty `BW_SESSION` triggers `bw unlock` only when stdin is a TTY; non-interactive runs must pass `BW_SESSION`.

```bash
# Preview the manifest plan without decrypting
ysh scripts/secret.ysh migrate --dry-run

# Encrypt every manifest entry; existing files are skipped
ysh scripts/secret.ysh migrate

# Replace files created by an earlier run
ysh scripts/secret.ysh migrate --force

# Rekey every host (all arguments are passed to agenix)
ysh scripts/secret.ysh rekey

# Edit a master secret
ysh scripts/secret.ysh edit secrets/master/hosts/BrokenPC/user_password_hash.age

# Check tools, manifest consistency, staging state, and Bitwarden status
ysh scripts/secret.ysh doctor
```

### Migration Manifest

[secrets/migration-manifest.json](../secrets/migration-manifest.json) records every legacy SOPS key and its disposition:

| Action | Effect |
| :--- | :--- |
| `encrypt` | Decrypts the SOPS key and writes an agenix master `.age` file at `target`. |
| `publish` | Writes public material, such as a Nebula CA certificate, to `target` in plaintext. |
| `generate` | Generates the value locally at service start; no file is written. |
| `drop` | Removes an unreferenced key; no file is written. |
| `bitwarden` | Moves the value to Bitwarden; no file is written. |

Entries with the same `target` and `format: "env"` are combined into one environment file, one `KEY=value` line per entry.

### Staged Imports

`.secrets-staging/` is a git-ignored area for plaintext that an agent or operator prepares without the master key. Paths mirror `secrets/master/`:

```text
.secrets-staging/hosts/BrokenPC/user_password_hash
  -> secrets/master/hosts/BrokenPC/user_password_hash.age
```

```bash
# Show the encryption plan without touching Bitwarden or the files
ysh scripts/secret.ysh apply-staging --dry-run

# Encrypt staged files, shred the plaintext, and rekey every host
ysh scripts/secret.ysh apply-staging

# Encrypt and remove staging files without rekeying
ysh scripts/secret.ysh apply-staging --no-rekey
```

## Just Recipes

The repository [justfile](../justfile) exposes the common workflows:

```bash
just secret-migrate
just secret-rekey
just secret-edit secrets/master/common/deploy_key.age
just secret-apply-staging
just check
just lint
just fmt path/to/file.nix
```

## Low-Level agenix Wrapper

```bash
# BW_SESSION is reused when set; otherwise the script prompts for the master password
ysh scripts/agenix-with-bw.ysh rekey -a
ysh scripts/agenix-with-bw.ysh edit secrets/master/example.age

# Point both Bitwarden and agenix-rekey at a custom identity directory
BW_MASTER_KEY_ITEM=agenix-master-key \
  AGENIX_MASTER_KEY_DIR=/run/user/1000/agenix \
  ysh scripts/agenix-with-bw.ysh rekey -a
```

Set `age.rekey.masterIdentities` to the same `master-key.txt` path. The file is created with mode 0600 and removed on exit.

## Other Workflows

### Set or Update Host Passwords

```bash
# Prompt for t3u and root passwords, hash with SHA-512, and update SOPS
SOPS_AGE_KEY_FILE=/path/to/master-key ysh scripts/set-host-password.ysh <hostname>
```

### Import Nebula Certificates into SOPS

```bash
# Import certificates into SOPS (the rotation script's default CA dir)
SOPS_AGE_KEY_FILE=/path/to/master-key ysh scripts/nebula-import-secrets.ysh ~/.nebula-ca-10-0-0
```

### Rotate Entire Nebula CA

```bash
# Generate a new CA and re-sign all fleet nodes
ysh scripts/nebula-rotate-ca.ysh ~/.nebula-ca-new --prefix 10.0.0

# Import new certs into SOPS host files
SOPS_AGE_KEY_FILE=/path/to/master-key ysh scripts/nebula-import-secrets.ysh ~/.nebula-ca-new
```

### Validate Markdown Links and Prose

```bash
# Lint markdown prose rules and validate relative links and heading anchors
perl scripts/check-docs.pl
```

## References

- Secret & certificate lifecycle: [docs/operations/secret-management.md](../docs/operations/secret-management.md)
- Host onboarding runbook: [docs/operations/adding-a-host.md](../docs/operations/adding-a-host.md)
- Nebula mesh topology: [docs/architecture/network-topology.md](../docs/architecture/network-topology.md)
