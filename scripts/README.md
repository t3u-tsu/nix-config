# Operational Scripts (`scripts/`)

Operator maintenance scripts for fleet management, credential provisioning, and certificate rotation, organized by domain, plus markdown validation scripts run by pre-commit.

## Scripts Overview

| Domain / Script | Purpose | Prerequisites |
| :--- | :--- | :--- |
| **Secrets Management** | | |
| [secrets/secret.ysh](secrets/secret.ysh) | Backward-compatibility router that forwards subcommands to the single-purpose scripts below. | Same as the target script |
| [secrets/rekey.ysh](secrets/rekey.ysh) | Re-encrypt every master secret for all hosts with the Bitwarden master identity. | `bw`, `age-keygen`, `agenix` |
| [secrets/edit.ysh](secrets/edit.ysh) | Decrypt a master secret into the noswap tmpfs, open it in `$EDITOR`, and wipe it on exit. | `bw`, `age-keygen`, `agenix` |
| [secrets/unlock.ysh](secrets/unlock.ysh) | Log in to Bitwarden or unlock the vault and hand the session to the in-memory agent. | `bw` |
| [secrets/lock.ysh](secrets/lock.ysh) | Lock Bitwarden and purge the in-memory session agent. | `bw`, `perl` |
| [secrets/apply-staging.ysh](secrets/apply-staging.ysh) | Encrypt plaintext under `.secrets-staging` into `secrets/master`, shred it, and optionally rekey. | `bw`, `age`, `age-keygen`, `agenix` |
| [secrets/set-host-password.ysh](secrets/set-host-password.ysh) | Hash the user password with yescrypt (`mkpasswd -m yescrypt`) and encrypt it to the master secrets. | `mkpasswd`, `bw`, `age`, `age-keygen` |
| [secrets/ssh-restore.ysh](secrets/ssh-restore.ysh) | Restore `~/.ssh/id_ed25519` and `.pub` from the Bitwarden `nix-config/ssh` folder. | `bw`, `ssh-keygen`, `base64` |
| [secrets/ssh-backup.ysh](secrets/ssh-backup.ysh) | Back up `~/.ssh/id_ed25519` and `.pub` to the Bitwarden `nix-config/ssh` folder. | `bw`, `ssh-keygen`, `base64` |
| [secrets/doctor.ysh](secrets/doctor.ysh) | Check tools, master identity consistency, the user SSH key, staging state, and Bitwarden status. | `bw`, `age`, `age-keygen`, `agenix`, `ssh-keygen`, `base64` |
| [secrets/lib/bitwarden.ysh](secrets/lib/bitwarden.ysh) | Shared Bitwarden session handling, master-identity extraction, SSH key item helpers, workflow helpers, and atomic encryption functions. | Sourced by secrets scripts |
| [secrets/lib/agent.pl](secrets/lib/agent.pl) | In-memory Bitwarden session daemon holding the session token strictly in process RAM over a Unix domain socket with an automatic sliding inactivity timeout. | `perl`, `bw` |
| **Nebula Mesh VPN** | | |
| [nebula/lib/fleet.ysh](nebula/lib/fleet.ysh) | Shared fleet loader importing node mappings (`name\|octet\|groups\|ip`) dynamically from [lib/nebula-fleet.nix](../lib/nebula-fleet.nix), with default CA directory and file helpers. | Sourced by Nebula scripts |
| [nebula/import-secrets.ysh](nebula/import-secrets.ysh) | Publishes Nebula CA and node certs, and encrypts node private keys to `secrets/master/hosts/<hostname>/nebula_key.age`. | `ysh`, `nix`, `bw`, `age`, `age-keygen` |
| [nebula/rotate-ca.ysh](nebula/rotate-ca.ysh) | One-shot Nebula CA recreation and bulk node re-signing. | `ysh`, `nix`, `nebula-cert`, `script`, `sort`, `base64` |
| **Documentation & QA** | | |
| [docs/lib/DocsLib.pm](docs/lib/DocsLib.pm) | Shared Perl module for repository root resolution, git-tracked file discovery, path normalization, and markdown code-fence stripping. | Perl core |
| [docs/check.pl](docs/check.pl) | Lints markdown prose (parentheses, commas, prohibited words, pseudo-headings) and validates relative links and heading anchors. | Perl core (run via pre-commit) |
| [docs/linkify.pl](docs/linkify.pl) | Scans markdown files and converts raw in-text file paths into relative links. | Perl core |
| **Hardware Quirks** | | |
| [hardware/restart-touchpad.ysh](hardware/restart-touchpad.ysh) | Recovers and rebinds the AMD I2C controller and Synaptics touchpad on HP Victus 16. | `ysh`, `pkexec` |
| **Host Installation & Provisioning** | | |
| [install/init-host-key.sh](install/init-host-key.sh) | Wrapper that runs `init-host-key.ysh` and installs `oils-for-unix` / `openssh` through `nix-shell` when missing. | `bash`, `nix-shell`, `ssh-keygen` |
| [install/init-host-key.ysh](install/init-host-key.ysh) | Generates the SSH host key in `<target_root>/etc/ssh` and prints the public key for `age.rekey.hostPubkey`. Reuses an existing key and refuses an unmounted target root. | `ysh`, `ssh-keygen`, `mountpoint` |
| [install/setup-deploy-key.sh](install/setup-deploy-key.sh) | Wrapper that runs `setup-deploy-key.ysh` and installs `oils-for-unix` / `age` / `openssh` through `nix-shell` when missing. | `bash`, `nix-shell`, `ssh-keyscan` |
| [install/setup-deploy-key.ysh](install/setup-deploy-key.ysh) | Decrypts `secrets/rekeyed/hosts/<hostname>/*-deploy_key.age` with the target host key and registers the `github-nix-config-private` SSH alias for private flake inputs. | `ysh`, `age`, `ssh`, `ssh-keyscan` |

Installer wrapper behaviour and usage are described in [install/README.md](install/README.md).

## Secret CLI

Run `just secret <recipe>` for the common operations, or call a single-purpose script directly. Each recipe is also listed by `just --list secret`. All command scripts, including [rekey](secrets/rekey.ysh), [edit](secrets/edit.ysh), [unlock](secrets/unlock.ysh), [lock](secrets/lock.ysh), [apply-staging](secrets/apply-staging.ysh), [set-host-password](secrets/set-host-password.ysh), [ssh-restore](secrets/ssh-restore.ysh), [ssh-backup](secrets/ssh-backup.ysh), and [doctor](secrets/doctor.ysh), share the Bitwarden helpers in [secrets/lib/bitwarden.ysh](secrets/lib/bitwarden.ysh). When no active session is present, interactive commands trigger `bw login` (when unauthenticated) or `bw unlock` (when locked) only when stdin is a TTY; non-interactive runs must pass `BW_SESSION`. Running [unlock](secrets/unlock.ysh) passes the session token to an in-memory resident agent daemon ([secrets/lib/agent.pl](secrets/lib/agent.pl)) over a mode 0600 Unix domain socket. The session token is held strictly in the agent process heap memory (RAM) and is never written to the file system (including tmpfs). Subsequent commands automatically retrieve the session over the socket without requiring `export BW_SESSION=...`. The agent maintains a sliding 15-minute inactivity timeout (configurable via `AGENIX_BW_SESSION_TTL`), refreshing the timer on each command. When the timeout expires, the agent zero-fills its memory, runs `bw lock`, and terminates. Under this fail-closed model, terminating or killing the agent process destroys the session without leaving any persisted plaintext files. Running [lock](secrets/lock.ysh) signals the agent to purge memory immediately and lock the vault. Commands re-execute under a systemd user scope with `MemorySwapMax=0`, and the master identity is written only to the dedicated noswap tmpfs at `/run/agenix-master`. Missing tools and Bitwarden states are reported with the command to fix them (for example `bw login` or `nix develop`).

The legacy [secrets/secret.ysh](secrets/secret.ysh) router still forwards `secret.ysh <command>` invocations to the matching script.

```bash
# Unlock Bitwarden and store the session in the in-memory agent (also supports --raw / --env)
ysh scripts/secrets/unlock.ysh

# Lock Bitwarden, zero agent memory, and terminate the agent
ysh scripts/secrets/lock.ysh

# Rekey every host (all arguments are passed to agenix)
ysh scripts/secrets/rekey.ysh

# Edit a master secret
ysh scripts/secrets/edit.ysh secrets/master/hosts/BrokenPC/user_password_hash.age

# Restore user SSH key (~/.ssh/id_ed25519 and .pub) from Bitwarden nix-config/ssh/<hostname>
ysh scripts/secrets/ssh-restore.ysh [hostname] [--file <path>] [--force]

# Back up local ~/.ssh/id_ed25519 to Bitwarden nix-config/ssh/<hostname>
ysh scripts/secrets/ssh-backup.ysh [hostname] [--file <path>] [--force]

# Check tools, master identity, ~/.ssh/id_ed25519 health, staging state, and Bitwarden status
ysh scripts/secrets/doctor.ysh
```

### Staged Imports

`.secrets-staging/` is a git-ignored area for plaintext that an agent or operator prepares without the master key. Paths mirror `secrets/master/`:

```text
.secrets-staging/hosts/BrokenPC/user_password_hash
  -> secrets/master/hosts/BrokenPC/user_password_hash.age
```

```bash
# Show the encryption plan without touching Bitwarden or the files
ysh scripts/secrets/apply-staging.ysh --dry-run

# Encrypt staged files, shred the plaintext, and rekey every host
ysh scripts/secrets/apply-staging.ysh

# Encrypt and remove staging files without rekeying
ysh scripts/secrets/apply-staging.ysh --no-rekey
```

### Common Justfile Recipes

```bash
# Secrets management (subcommand: just secret <recipe>, legacy: just secret-<recipe>)
just secret unlock
just secret rekey
just secret edit secrets/master/hosts/BrokenPC/user_password_hash.age
just secret apply-staging
just secret ssh-restore
just secret ssh-backup
just secret doctor
just secret lock

# System operations (subcommand: just system <recipe>)
just switch
just diff
just test
just build
just system boot
just system gc
just system rollback
just system info

# Dependency updates
just update flake
just update nvfetcher

# QA and documentation
just check
just lint
just fmt path/to/file.nix
just docs check
just docs linkify

# Nebula mesh VPN
just nebula rotate-ca
just nebula import-secrets

# Hardware quirks
just hardware restart-touchpad
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
just secret set-host-password --all
just secret set-host-password BrokenPC x1c7
# or: ysh scripts/secrets/set-host-password.ysh BrokenPC x1c7

# Propagate the new hashes into secrets/rekeyed/hosts/
just secret rekey
```

### Rotate the Fleet Nebula CA

A full CA rotation issues a new root CA and signs all node certificates anew:

```bash
# Generate a new CA in ~/.nebula-ca and issue certs for every node in lib/nebula-fleet.nix
just nebula rotate-ca
# or: ysh scripts/nebula/rotate-ca.ysh

# Publish ca.crt / hosts/<name>/nebula.crt and encrypt keys to secrets/master/
just nebula import-secrets
# or: ysh scripts/nebula/import-secrets.ysh

# Distribute rekeyed secrets to each host
just secret rekey
```
