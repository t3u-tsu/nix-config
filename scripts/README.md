# Operational Scripts (`scripts/`)

Operator maintenance scripts for fleet management, credential provisioning, and certificate rotation, organized by domain, plus markdown validation scripts run by pre-commit.

## Scripts Overview

| Domain / Script | Purpose | Prerequisites |
| :--- | :--- | :--- |
| **Shared Libraries** | | |
| [lib/common.ysh](lib/common.ysh) | Shared YSH helpers (`file_exists`, `path_exists`, `command_exists`, `die`, `issue_temp_password`, `sha512_crypt_hash`). | Sourced by YSH scripts |
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
| [install/init-host-key.sh](install/init-host-key.sh) | Wrapper that runs [init-host-key.ysh](install/init-host-key.ysh) and installs `oils-for-unix` / `openssh` through `nix-shell` when missing. | `bash`, `nix-shell`, `ssh-keygen` |
| [install/init-host-key.ysh](install/init-host-key.ysh) | Generates the SSH host key in `<target_root>/etc/ssh` and prints the public key for `age.rekey.hostPubkey`. Reuses an existing key and refuses an unmounted target root. | `ysh`, `ssh-keygen`, `mountpoint` |
| [install/setup-deploy-key.sh](install/setup-deploy-key.sh) | Wrapper that runs [setup-deploy-key.ysh](install/setup-deploy-key.ysh) and installs `oils-for-unix` / `age` / `openssh` through `nix-shell` when missing. | `bash`, `nix-shell`, `ssh-keyscan` |
| [install/setup-deploy-key.ysh](install/setup-deploy-key.ysh) | Decrypts `secrets/rekeyed/hosts/<hostname>/*-deploy_key.age` with the target host key and registers the `github-nix-config-private` SSH alias for private flake inputs. | `ysh`, `age`, `ssh`, `ssh-keyscan` |

Installer wrapper behaviour and usage are described in [install/README.md](install/README.md).

## CLI Quick Reference

Inside `nix develop`, [justfile](../justfile) wraps the scripts under `just <group> <recipe>`:

```bash
# Secrets management (just --list secret)
just secret unlock
just secret rekey
just secret edit secrets/master/hosts/BrokenPC/user_password_hash.age
just secret apply-staging [--dry-run | --no-rekey]
just secret set-host-password [--all | <host>...]
just secret ssh-restore [hostname] [--file <path>] [--force]
just secret ssh-backup [hostname] [--file <path>] [--force]
just secret doctor
just secret lock

# System operations (just --list system)
just switch
just diff
just test
just build
just system boot | gc | rollback | info

# Dependency updates
just update flake | nvfetcher

# QA and documentation
just check
just lint
just fmt path/to/file.nix
just docs check | linkify

# Nebula mesh VPN
just nebula rotate-ca
just nebula import-secrets

# Hardware quirks
just hardware restart-touchpad
```

### Environment Variables (`secrets/`)

| Variable | Purpose | Default |
| :--- | :--- | :--- |
| `BW_SESSION` | Bitwarden session token for non-interactive runs | Retrieved from [secrets/lib/agent.pl](secrets/lib/agent.pl) |
| `AGENIX_BW_SESSION_TTL` | In-memory session agent sliding inactivity timeout (seconds) | `900` (15 minutes) |
| `AGENIX_REQUIRE_SWAP_GUARD` | Set to `1` to fail closed if `systemd-run --user` (`MemorySwapMax=0`) cannot be entered | Unset |
| `AGENIX_MASTER_KEY_DIR_ALLOW_UNSAFE` | Set to `1` to allow non-tmpfs master key directories | Unset |

## References

- Secret management & Bitwarden/age/SSH runbook: [docs/operations/secret-management.md](../docs/operations/secret-management.md)
- Host installation scripts: [scripts/install/README.md](install/README.md)
- Encrypted secrets directory: [secrets/README.md](../secrets/README.md)
