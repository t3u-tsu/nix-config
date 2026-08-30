#!/usr/bin/env bash
#
# scripts/nebula-import-secrets.sh
#
# Import the Nebula CA / node certificates & keys into SOPS secrets.
#
# Why: the node private keys are stored per-host in secrets/hosts/<host>.yaml,
# which deliberately EXCLUDES the user key (only the master key + each host's
# SSH-derived age key can decrypt it). The agent environment only holds the
# user key, so this step must be run by the operator WITH ACCESS TO THE MASTER
# KEY (or on each host with its own SSH host key).
#
# Usage:
#   SOPS_AGE_KEY_FILE=/path/to/master-age-key.txt \
#     bash scripts/nebula-import-secrets.sh [CA_DIR]
#
#   CA_DIR defaults to ~/.nebula-ca (where nebula-cert wrote the files).
#
# The node list comes from scripts/nebula-lib.sh (FLEET) — add a new host
# there, sign its cert, then re-run this script (see hosts/README.md).
#
# Idempotent: safe to re-run (e.g. after certificate rotation).
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CA_DIR="${1:-$HOME/.nebula-ca}"

# shellcheck disable=SC1091 # nebula-lib.sh is followed via -x (see dev.nix)
# shellcheck source=nebula-lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/nebula-lib.sh"

cd "$REPO_ROOT"

# --- CA certificate (shared) -> secrets/common.yaml -----------------------
if [[ -f "$CA_DIR/ca.crt" ]]; then
  sops set secrets/common.yaml '["nebula_ca"]' "$(jq -Rs . < "$CA_DIR/ca.crt")"
  echo "OK: nebula_ca -> secrets/common.yaml"
else
  echo "SKIP: $CA_DIR/ca.crt not found" >&2
fi

# --- per-host certificate + key -> secrets/hosts/<name>.yaml -------------
for entry in "${FLEET[@]}"; do
  name="${entry%%|*}"
  file="$(host_secrets_file "$name")"
  prefix="$(host_key "$name")"

  if [[ ! -f "$CA_DIR/$name.crt" || ! -f "$CA_DIR/$name.key" ]]; then
    echo "SKIP: $CA_DIR/$name.{crt,key} not found" >&2
    continue
  fi

  sops set "$file" "[\"${prefix}_nebula_cert\"]" "$(jq -Rs . < "$CA_DIR/$name.crt")"
  sops set "$file" "[\"${prefix}_nebula_key\"]" "$(jq -Rs . < "$CA_DIR/$name.key")"
  echo "OK: ${prefix}_nebula_cert / ${prefix}_nebula_key -> $file"
done

# --- verify ----------------------------------------------------------------
echo
echo "All Nebula secrets imported. Verifying..."
for entry in "${FLEET[@]}"; do
  name="${entry%%|*}"
  file="$(host_secrets_file "$name")"
  prefix="$(host_key "$name")"
  if sops --decrypt "$file" | grep -q "${prefix}_nebula_cert"; then
    echo "  OK: $file (${prefix}_nebula_cert)"
  else
    echo "  MISSING: $file (${prefix}_nebula_cert)" >&2
  fi
done