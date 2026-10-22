# Operational Scripts (`scripts/`)

Operator maintenance scripts for fleet management, credential provisioning, and certificate rotation, plus markdown validation scripts run by pre-commit.

## Scripts Overview

| Script | Purpose | Prerequisites |
| :--- | :--- | :--- |
| [nebula-lib.ysh](nebula-lib.ysh) | Shared fleet registry defining `FLEET` node mappings (`name\|last-octet\|groups`) and path helpers. | Sourced by Nebula scripts |
| [nebula-import-secrets.ysh](nebula-import-secrets.ysh) | Imports Nebula CA and host certs/keys into SOPS host files. | `SOPS_AGE_KEY_FILE` (Master key) |
| [nebula-rotate-ca.ysh](nebula-rotate-ca.ysh) | One-shot Nebula CA recreation and bulk node re-signing. | `nebula-cert` on PATH |
| [set-host-password.ysh](set-host-password.ysh) | Hashes user/root passwords (`mkpasswd`) and injects hashes into `secrets/hosts/<hostname>.yaml`. | `mkpasswd`, `sops`, `SOPS_AGE_KEY_FILE` |
| [check-docs.pl](check-docs.pl) | Lints markdown prose (parentheses, commas, prohibited words, pseudo-headings) and validates relative links and heading anchors. | Perl core (run via pre-commit) |
| [linkify-markdown.pl](linkify-markdown.pl) | Scans markdown files and converts raw in-text file paths into relative links. | Perl core |
| [restart-touchpad.ysh](restart-touchpad.ysh) | Recovers and rebinds the AMD I2C controller and Synaptics touchpad on HP Victus 16. | `ysh`, `pkexec` |

## Usage Examples

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
