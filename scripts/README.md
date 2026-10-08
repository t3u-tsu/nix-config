# scripts/ — Operational Scripts

Operator-run scripts (not part of the NixOS build).

## Shared fleet data

- **`nebula-lib.sh`**: source-only helper defining `FLEET` — the single node list
  (`<name>|<last-octet>|<groups>`) — plus the `host_key` / `host_secrets_file`
  helpers. Add a new host here, then sign and import its cert (see [`docs/operations/adding-a-host.md`](../docs/operations/adding-a-host.md)).

## Scripts

- **`set-host-password.sh`**: prompts for the t3u / root passwords and writes
  their sha-512 hashes into `secrets/hosts/<hostname>.yaml` via sops. Updating an
  existing file needs the offline master age key (`SOPS_AGE_KEY_FILE`) to keep its
  other keys; `mkpasswd`, `sops` and `jq` must be on PATH.
- **`nebula-import-secrets.sh [CA_DIR]`**: imports the Nebula CA / node certs into SOPS
  (`CA_DIR` defaults to `~/.nebula-ca`). Needs the master key (`SOPS_AGE_KEY_FILE`).
  Idempotent.
- **`nebula-rotate-ca.sh [CA_DIR] [--prefix 10.0.0]`**: one-shot CA rotation (new CA, re-sign every node).
  `CA_DIR` defaults to `~/.nebula-ca-<prefix, dots->hyphens>` and `--prefix` defaults to `10.0.0`.
  Re-import is a separate step via `nebula-import-secrets.sh`. For a single new
  host, sign one cert against the existing CA instead.

Both Nebula scripts read `FLEET` from `nebula-lib.sh`; cert basenames and SOPS key
prefixes are derived from it.

## References
- Secret & certificate lifecycle: [`docs/operations/secret-management.md`](../docs/operations/secret-management.md)
- Adding a new host runbook: [`docs/operations/adding-a-host.md`](../docs/operations/adding-a-host.md)
- Network topology & IP allocation: [`docs/architecture/network-topology.md`](../docs/architecture/network-topology.md)
