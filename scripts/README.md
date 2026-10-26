# Operational Scripts (`scripts/`)

Operator maintenance scripts for fleet management, credential provisioning, and certificate rotation, organized by domain, plus markdown validation scripts run by pre-commit.

## Scripts Overview

| Domain / Script | Purpose | Prerequisites |
| :--- | :--- | :--- |
| **Secrets Management** | | |
| [secrets/secret.ysh](secrets/secret.ysh) | Unified CLI for rekey, editing, staged imports, user SSH key sync, and environment checks. | `bw`, `age`, `age-keygen`, `agenix`, `ssh-keygen`, `base64` |
| [secrets/agenix-bw-lib.ysh](secrets/agenix-bw-lib.ysh) | Shared Bitwarden session handling, master-identity extraction, SSH key item lookup, and atomic encryption helpers used by `secret.ysh`. | `bw`, `age`, `age-keygen`, `ssh-keygen`, `base64` |
| [secrets/set-host-password.ysh](secrets/set-host-password.ysh) | Hashes user password with yescrypt (`mkpasswd -m yescrypt`) and writes `secrets/master/hosts/<hostname>/user_password_hash.age`. | `mkpasswd`, `bw`, `age`, `age-keygen` |
| **Nebula Mesh VPN** | | |
| [nebula/nebula-lib.ysh](nebula/nebula-lib.ysh) | Shared fleet registry defining `FLEET` node mappings (`name\|last-octet\|groups`), the default CA directory, and file helpers. | Sourced by Nebula scripts |
| [nebula/nebula-import-secrets.ysh](nebula/nebula-import-secrets.ysh) | Publishes Nebula CA and node certs, and encrypts node private keys to `secrets/master/hosts/<hostname>/nebula_key.age`. | `bw`, `age`, `age-keygen` |
| [nebula/nebula-rotate-ca.ysh](nebula/nebula-rotate-ca.ysh) | One-shot Nebula CA recreation and bulk node re-signing. | `nebula-cert`, `script`, `sort`, `base64` |
| **Documentation & QA** | | |
| [docs/check-docs.pl](docs/check-docs.pl) | Lints markdown prose (parentheses, commas, prohibited words, pseudo-headings) and validates relative links and heading anchors. | Perl core (run via pre-commit) |
| [docs/linkify-markdown.pl](docs/linkify-markdown.pl) | Scans markdown files and converts raw in-text file paths into relative links. | Perl core |
| **Hardware Quirks** | | |
| [hardware/restart-touchpad.ysh](hardware/restart-touchpad.ysh) | Recovers and rebinds the AMD I2C controller and Synaptics touchpad on HP Victus 16. | `ysh`, `pkexec` |
| **Host Installation & Provisioning** | | |
| [install/init-host-key.sh](install/init-host-key.sh) | Wrapper that runs `init-host-key.ysh` and installs `oils-for-unix` / `openssh` through `nix-shell` when missing. | `bash`, `nix-shell`, `ssh-keygen` |
| [install/init-host-key.ysh](install/init-host-key.ysh) | Generates the SSH host key in `<target_root>/etc/ssh` and prints the public key for `age.rekey.hostPubkey`. Reuses an existing key and refuses an unmounted target root. | `ysh`, `ssh-keygen`, `mountpoint` |
| [install/setup-deploy-key.sh](install/setup-deploy-key.sh) | Wrapper that runs `setup-deploy-key.ysh` and installs `oils-for-unix` / `age` / `openssh` through `nix-shell` when missing. | `bash`, `nix-shell`, `ssh-keyscan` |
| [install/setup-deploy-key.ysh](install/setup-deploy-key.ysh) | Decrypts `secrets/rekeyed/hosts/<hostname>/*-deploy_key.age` with the target host key and registers the `github-nix-config-private` SSH alias for private flake inputs. | `ysh`, `age`, `ssh`, `ssh-keyscan` |

## Secret CLI

`scripts/secrets/secret.ysh` wraps the Bitwarden master identity and the agenix-rekey commands. An empty `BW_SESSION` triggers `bw unlock` only when stdin is a TTY; non-interactive runs must pass `BW_SESSION`. Commands re-execute under a systemd user scope with `MemorySwapMax=0`, and the master identity is written only to the dedicated noswap tmpfs at `/run/agenix-master`. Missing tools and Bitwarden states are reported with the command to fix them (for example `bw login` or `nix develop`).

```bash
# Rekey every host (all arguments are passed to agenix)
ysh scripts/secrets/secret.ysh rekey

# Edit a master secret
ysh scripts/secrets/secret.ysh edit secrets/master/hosts/BrokenPC/user_password_hash.age

# Restore user SSH key (~/.ssh/id_ed25519 and .pub) from Bitwarden nix-config/ssh/<hostname>
ysh scripts/secrets/secret.ysh ssh-restore [hostname] [--file <path>] [--force]

# Back up local ~/.ssh/id_ed25519 to Bitwarden nix-config/ssh/<hostname>
ysh scripts/secrets/secret.ysh ssh-backup [hostname] [--file <path>] [--force]

# Check tools, master identity, ~/.ssh/id_ed25519 health, staging state, and Bitwarden status
ysh scripts/secrets/secret.ysh doctor
```

### Staged Imports

`.secrets-staging/` is a git-ignored area for plaintext that an agent or operator prepares without the master key. Paths mirror `secrets/master/`:

```text
.secrets-staging/hosts/BrokenPC/user_password_hash
  -> secrets/master/hosts/BrokenPC/user_password_hash.age
```

```bash
# Show the encryption plan without touching Bitwarden or the files
ysh scripts/secrets/secret.ysh apply-staging --dry-run

# Encrypt staged files, shred the plaintext, and rekey every host
ysh scripts/secrets/secret.ysh apply-staging

# Encrypt and remove staging files without rekeying
ysh scripts/secrets/secret.ysh apply-staging --no-rekey
```

### Common Justfile Recipes

```bash
just secret-rekey
just secret-edit secrets/master/hosts/BrokenPC/user_password_hash.age
just secret-apply-staging
just secret-ssh-restore
just secret-ssh-backup
just secret-doctor
just check
just lint
just fmt path/to/file.nix
```

## Secret CLI Configuration

Set `age.rekey.masterIdentities` to the same `master-key.txt` path. The default
is the dedicated noswap tmpfs at `/run/agenix-master`; the file is created with
mode 0400 and removed on exit, including on signals (EXIT/INT/TERM/HUP/QUIT). The CLI
re-executes itself under a systemd user scope with `MemorySwapMax=0`; set
`AGENIX_REQUIRE_SWAP_GUARD=1` to fail closed when that scope cannot be entered.
Non-tmpfs override directories require `AGENIX_MASTER_KEY_DIR_ALLOW_UNSAFE=1`.

## Other Workflows

### Set or Update Host Passwords

```bash
# Prompt for user password (with confirmation), hash with yescrypt (independent salts per host),
# and write master secrets (supports specific hosts or --all)
just secret-set-host-password --all
just secret-set-host-password BrokenPC x1c7
# or: ysh scripts/secrets/set-host-password.ysh BrokenPC x1c7

# Propagate the new hashes into secrets/rekeyed/hosts/
just secret-rekey
```

### Rotate the Fleet Nebula CA

A full CA rotation issues a new root CA and signs all node certificates anew:

```bash
# Generate a new CA in ~/.nebula-ca and issue certs for all nodes in FLEET
ysh scripts/nebula/nebula-rotate-ca.ysh

# Publish ca.crt / hosts/<name>/nebula.crt and encrypt keys to secrets/master/
ysh scripts/nebula/nebula-import-secrets.ysh

# Distribute rekeyed secrets to each host
just secret-rekey
```
