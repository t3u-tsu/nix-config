#!/usr/bin/env bash
#
# Rotate the whole Nebula CA. Node IPs live inside the signed certs and are
# bounded by the CA's -networks, so a subnet change or CA expiry means issuing a
# new CA and re-signing every node — for a single new host, sign one cert
# against the existing CA instead. Re-running issues a NEW CA; only the
# passphrase in $CA_DIR/passphrase (chmod 600) is reused.
#
# Usage:
#   bash scripts/nebula-rotate-ca.sh [CA_DIR] [--prefix 10.0.0]
#
#   CA_DIR defaults to ~/.nebula-ca-<prefix, dots->hyphens>; --prefix is the first
#   three octets of the new overlay subnet. The node list comes from
#   scripts/nebula-lib.sh (FLEET).
#
# Re-importing the new certs into SOPS is a separate step that needs the offline
# master age key:
#   SOPS_AGE_KEY_FILE=... bash scripts/nebula-import-secrets.sh "$CA_DIR"
set -euo pipefail

# shellcheck disable=SC1091 # nebula-lib.sh is followed via -x (see dev.nix)
# shellcheck source=nebula-lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/nebula-lib.sh"

CA_NAME="t3u-home-ca"
DURATION="87600h" # 10y

# Union of every group used in the fleet; the CA must permit all of them.
CA_GROUPS="$(for entry in "${FLEET[@]}"; do
  IFS='|' read -r _ _ groups <<< "$entry"
  tr ',' '\n' <<< "$groups"
done | sort -u | paste -sd, -)"

CA_DIR=""
PREFIX="10.0.0"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix)
      PREFIX="$2"
      shift 2
      ;;
    *)
      CA_DIR="$1"
      shift
      ;;
  esac
done
subnet_dir="${PREFIX//./-}"
CA_DIR="${CA_DIR:-$HOME/.nebula-ca-$subnet_dir}"
SUBNET="$PREFIX.0/24"

echo "== Nebula CA rotation =="
echo "  CA dir : $CA_DIR"
echo "  subnet : $SUBNET"
echo "  CA gps : $CA_GROUPS"

mkdir -p "$CA_DIR"
cd "$CA_DIR"

if [[ ! -f passphrase ]]; then
  head -c 24 /dev/urandom | base64 > passphrase
fi
chmod 600 passphrase
PF="$(cat passphrase)"

# nebula-cert prompts for the passphrase; a pty satisfies it.
run_nebula() {
  script -qec "nix shell nixpkgs#nebula -c $*" /dev/null <<EOF
$PF
EOF
}

echo "== creating CA =="
run_nebula nebula-cert ca \
  -name "$CA_NAME" \
  -networks "$SUBNET" \
  -groups "$CA_GROUPS" \
  -duration "$DURATION" \
  -encrypt \
  -out-crt ca.crt \
  -out-key ca.key

for entry in "${FLEET[@]}"; do
  IFS='|' read -r name octet groups <<< "$entry"
  ip="$PREFIX.$octet"
  echo "== sign $name ($ip/24, $groups) =="
  run_nebula nebula-cert sign \
    -name "$name" \
    -networks "$ip/24" \
    -groups "$groups" \
    -ca-crt ca.crt \
    -ca-key ca.key \
    -out-crt "$name.crt" \
    -out-key "$name.key"
done

echo
echo "== done. Certificates written to $CA_DIR =="
echo "Next, re-import into SOPS (needs the offline MASTER key):"
echo "  SOPS_AGE_KEY_FILE=/path/to/master-age-key.txt bash scripts/nebula-import-secrets.sh $CA_DIR"
