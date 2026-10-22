# SOPS Encrypted Secrets (`secrets/`)

SOPS-encrypted secrets using Age encryption keys. Never commit plaintext secrets to version control.

## Secret File Structure

| Directory / File | Scope | Description |
| :--- | :--- | :--- |
| `hosts/<hostname>.yaml` | Host-specific | User password hashes, Nebula private keys, and host credentials. |
| `services/<service>.yaml` | Service-specific | Service secrets shared by assigned hosts (Cloudflare DDNS, Minecraft, Discord, Restic, ConoHa API). |
| [`common.yaml`](common.yaml) | Fleet-wide | Secrets shared across all managed machines. |

## Key Distribution Model ([`.sops.yaml`](../.sops.yaml))

- The master key (`master_key`) serves as an offline disaster-recovery Age key stored in a password manager (1Password) and is included in every encryption group.
- Host keys are derived from `/etc/ssh/ssh_host_ed25519_key.pub` via `ssh-to-age`, allowing machines to decrypt secrets automatically during boot.
- User keys are derived from user workstation keys (`~/.ssh/id_ed25519`), restricting access to developer and service files ([`services/signing.yaml`](services/signing.yaml), [`services/conoha-vps-mcp.yaml`](services/conoha-vps-mcp.yaml)).

### Access Matrix

| Secret Target | Master Key | Host Keys | User Workstation Keys |
| :--- | :---: | :---: | :---: |
| `hosts/<hostname>.yaml` | :white_check_mark: | :white_check_mark: (Target host only) | :x: |
| [`common.yaml`](common.yaml) | :white_check_mark: | :white_check_mark: (All hosts) | :x: |
| [`services/minecraft.yaml`](services/minecraft.yaml) | :white_check_mark: | :white_check_mark: (`shosoin_tan`) | :x: |
| [`services/backup.yaml`](services/backup.yaml) | :white_check_mark: | :white_check_mark: (`shosoin_tan`) | :x: |
| [`services/ddns.yaml`](services/ddns.yaml) | :white_check_mark: | :white_check_mark: (`torii_chan`) | :x: |
| [`services/signing.yaml`](services/signing.yaml) | :white_check_mark: | :x: | :white_check_mark: |
| [`services/conoha-vps-mcp.yaml`](services/conoha-vps-mcp.yaml) | :white_check_mark: | :x: | :white_check_mark: |

## Common Workflows

### Editing a Secret File

```bash
# For host secrets (requires master key)
SOPS_AGE_KEY_FILE=/path/to/master-key sops secrets/hosts/<hostname>.yaml

# For user-accessible services (opens with ~/.config/sops/age/keys.txt)
sops secrets/services/signing.yaml
```

### Rotating a Host Key

Regenerate the host SSH key, e.g. after a clean reflash:

1. Derive the new Age public key using `ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub`.
2. Update [`.sops.yaml`](../.sops.yaml) with the new key.
3. Re-encrypt with the master key:
   ```bash
   SOPS_AGE_KEY_FILE=/path/to/master-key sops updatekeys secrets/hosts/<hostname>.yaml
   SOPS_AGE_KEY_FILE=/path/to/master-key sops updatekeys secrets/common.yaml
   # Also update each service file the host can decrypt (e.g. services/backup.yaml and
   # services/minecraft.yaml for shosoin_tan).
   SOPS_AGE_KEY_FILE=/path/to/master-key sops updatekeys secrets/services/<service>.yaml
   ```

## References

- Secret management runbook: [`docs/operations/secret-management.md`](../docs/operations/secret-management.md)
- Secret recovery troubleshooting: [`docs/troubleshooting/secrets-and-auth.md`](../docs/troubleshooting/secrets-and-auth.md)
- Host onboarding runbook: [`docs/operations/adding-a-host.md`](../docs/operations/adding-a-host.md)
