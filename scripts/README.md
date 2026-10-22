# Operational Scripts (`scripts/`)

Operator maintenance scripts written in [YSH](https://www.oilshell.org/) for fleet management, credential provisioning, and certificate rotation.

## Scripts Overview

| Script | Purpose | Prerequisites |
| :--- | :--- | :--- |
| [nebula-lib.ysh](nebula-lib.ysh) | Shared fleet registry defining `FLEET` node mappings (`name\|last-octet\|groups`) and path helpers. | Sourced by Nebula scripts |
| [nebula-import-secrets.ysh](nebula-import-secrets.ysh) | Imports Nebula CA and host certs/keys into SOPS host files. | `SOPS_AGE_KEY_FILE` (Master key) |
| [nebula-rotate-ca.ysh](nebula-rotate-ca.ysh) | One-shot Nebula CA recreation and bulk node re-signing. | `nebula-cert` on PATH |
| [set-host-password.ysh](set-host-password.ysh) | Hashes user/root passwords (`mkpasswd`) and injects hashes into `secrets/hosts/<hostname>.yaml`. | `mkpasswd`, `sops`, `SOPS_AGE_KEY_FILE` |
| [check-markdown-links.py](check-markdown-links.py) | Validates that all relative markdown links point to existing files and heading anchors. | Python 3 (run via pre-commit) |
| [check-docs.ysh](check-docs.ysh) | Detects full-width parentheses, prohibited words, and pseudo-heading bullets in markdown prose. | YSH (run via pre-commit) |
| [linkify-markdown.py](linkify-markdown.py) | Scans markdown files and converts raw in-text file paths into relative links. | Python 3 |

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
# Check relative links and heading anchors across the repository
python3 scripts/check-markdown-links.py

# Check full-width parentheses, prohibited words, and pseudo-heading bullets
ysh scripts/check-docs.ysh
```

## References

- Secret & certificate lifecycle: [docs/operations/secret-management.md](../docs/operations/secret-management.md)
- Host onboarding runbook: [docs/operations/adding-a-host.md](../docs/operations/adding-a-host.md)
- Nebula mesh topology: [docs/architecture/network-topology.md](../docs/architecture/network-topology.md)
