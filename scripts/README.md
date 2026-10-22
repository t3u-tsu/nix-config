# Operational Scripts (`scripts/`)

Operator maintenance scripts written in [YSH](https://www.oilshell.org/) for fleet management, credential provisioning, and certificate rotation.

## Scripts Overview

| Script | Purpose | Prerequisites |
| :--- | :--- | :--- |
| `nebula-lib.ysh` | Shared fleet registry defining `FLEET` node mappings (`name\|last-octet\|groups`) and path helpers. | Sourced by Nebula scripts |
| `nebula-import-secrets.ysh` | Imports Nebula CA and host certs/keys into SOPS host files. | `SOPS_AGE_KEY_FILE` (Master key) |
| `nebula-rotate-ca.ysh` | One-shot Nebula CA recreation and bulk node re-signing. | `nebula-cert` on PATH |
| `set-host-password.ysh` | Hashes user/root passwords (`mkpasswd`) and injects hashes into `secrets/hosts/<hostname>.yaml`. | `mkpasswd`, `sops`, `SOPS_AGE_KEY_FILE` |

## Usage Examples

### Set or Update Host Passwords

```bash
# Prompts for t3u and root passwords, hashes with SHA-512, and updates SOPS
SOPS_AGE_KEY_FILE=/path/to/master-key ysh scripts/set-host-password.ysh <hostname>
```

### Import Nebula Certificates into SOPS

```bash
# Imports certificates from ~/.nebula-ca into SOPS
SOPS_AGE_KEY_FILE=/path/to/master-key ysh scripts/nebula-import-secrets.ysh ~/.nebula-ca
```

### Rotate Entire Nebula CA

```bash
# Generate a new CA and re-sign all fleet nodes
ysh scripts/nebula-rotate-ca.ysh ~/.nebula-ca-new --prefix 10.0.0

# Import new certs into SOPS host files
SOPS_AGE_KEY_FILE=/path/to/master-key ysh scripts/nebula-import-secrets.ysh ~/.nebula-ca-new
```

## References

- Secret & certificate lifecycle: [`docs/operations/secret-management.md`](../docs/operations/secret-management.md)
- Host onboarding runbook: [`docs/operations/adding-a-host.md`](../docs/operations/adding-a-host.md)
- Nebula mesh topology: [`docs/architecture/network-topology.md`](../docs/architecture/network-topology.md)
