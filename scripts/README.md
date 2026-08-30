# scripts/ — Operational Scripts

Operator-run scripts (not part of the NixOS build).

## Scripts

- **`nebula-import-secrets.sh`**: Import Nebula CA / node certificates & keys into SOPS secrets (`secrets/common.yaml` + `secrets/hosts/*.yaml`). Requires the offline **master age key** (`SOPS_AGE_KEY_FILE`). Idempotent — safe to re-run after rotation.
- **`nebula-rotate-ca.sh`**: One-shot Nebula CA rotation — create a new CA, re-sign every node certificate for a (possibly new) overlay subnet, and populate the CA directory. SOPS re-import is a separate step via `nebula-import-secrets.sh`.