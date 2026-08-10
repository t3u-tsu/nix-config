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
#   # Make your master age private key available, e.g.:
#   export SOPS_AGE_KEY_FILE=/path/to/master-age-key.txt
#   bash scripts/nebula-import-secrets.sh [CA_DIR]
#
#   CA_DIR defaults to ~/.nebula-ca (where nebula-cert wrote the files).
#
# Idempotent: safe to re-run (e.g. after certificate rotation).
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CA_DIR="${1:-$HOME/.nebula-ca}"

cd "$REPO_ROOT"

# host file | sops secret prefix | cert basename
HOSTS=(
  "secrets/hosts/torii-chan.yaml|torii_chan|torii-chan"
  "secrets/hosts/sando-kun.yaml|sando_kun|sando-kun"
  "secrets/hosts/kagutsuchi-sama.yaml|kagutsuchi_sama|kagutsuchi-sama"
  "secrets/hosts/shosoin-tan.yaml|shosoin_tan|shosoin-tan"
  "secrets/hosts/BrokenPC.yaml|brokenpc|BrokenPC"
)

# --- CA certificate (shared) -> secrets/common.yaml ---------------------
if [[ -f "$CA_DIR/ca.crt" ]]; then
  ca_json="$(jq -Rs . < "$CA_DIR/ca.crt")"
  sops set secrets/common.yaml '["nebula_ca"]' "$ca_json"
  echo "OK: nebula_ca  -> secrets/common.yaml"
else
  echo "SKIP: $CA_DIR/ca.crt not found" >&2
fi

# --- per-host certificate + key -> secrets/hosts/<host>.yaml ------------
for entry in "${HOSTS[@]}"; do
  file="${entry%%|*}"
  prefix="${entry#*|}"
  prefix="${prefix%%|*}"
  name="${entry##*|}"

  if [[ ! -f "$CA_DIR/$name.crt" || ! -f "$CA_DIR/$name.key" ]]; then
    echo "SKIP: $CA_DIR/$name.{crt,key} not found" >&2
    continue
  fi

  cert_json="$(jq -Rs . < "$CA_DIR/$name.crt")"
  key_json="$(jq -Rs . < "$CA_DIR/$name.key")"

  sops set "$file" "[\"${prefix}_nebula_cert\"]" "$cert_json"
  sops set "$file" "[\"${prefix}_nebula_key\"]"  "$key_json"
  echo "OK: ${prefix}_nebula_cert / ${prefix}_nebula_key -> $file"
done

echo
echo "All Nebula secrets imported. Verifying..."
sops --decrypt secrets/common.yaml | grep -q nebula_ca && echo "  common.yaml: nebula_ca OK"
for entry in "${HOSTS[@]}"; do
  file="${entry%%|*}"
  prefix="${entry#*|}"
  prefix="${prefix%%|*}"
  if sops --decrypt "$file" | grep -q "${prefix}_nebula_cert"; then
    echo "  $file: ${prefix}_nebula_cert OK"
  else
    echo "  $file: MISSING $(basename "$file") secrets" >&2
  fi
done