# scripts/ — Operational Scripts

Operator-run scripts (not part of the NixOS build).

## Shared fleet data

- **`nebula-lib.sh`**: source-only helper (not executable) defining `FLEET` —
  the single node list (`<name>|<last-octet>|<groups>`, see the file header) —
  plus the `host_key` / `host_secrets_file` helpers. **Add a new host here**
  (one line), then sign its cert and import it — see `hosts/README.md`.

## Scripts

- **`nebula-import-secrets.sh`**: Import Nebula CA / node certificates & keys
  into SOPS secrets (`secrets/common.yaml` + `secrets/hosts/*.yaml`). Requires
  the offline **master age key** (`SOPS_AGE_KEY_FILE`). Idempotent — safe to
  re-run after rotation.
- **`nebula-rotate-ca.sh`**: One-shot full Nebula CA rotation — create a new
  CA, re-sign every node certificate for a (possibly new) overlay subnet, and
  populate the CA directory. SOPS re-import is a separate step via
  `nebula-import-secrets.sh`. For a single new host, sign one cert against the
  existing CA instead (see `hosts/README.md`).

Both scripts read the node list from `nebula-lib.sh` (`FLEET`); the
certificate basenames and SOPS key prefixes are derived from it, so a host is
added in exactly one place.
