#!/usr/bin/env bash
#
# scripts/nebula-rotate-ca.sh
#
# Rotate the Nebula CA in one shot: create a brand-new CA, re-sign every node
# certificate for a new overlay subnet, and leave the fleet's CA_DIR populated
# with the fresh `*.crt` / `*.key` files.
#
# Why this exists: Nebula node IPs live *inside* the signed certificates and are
# constrained by the CA's `-networks`. Changing the overlay subnet (or the CA
# expiring) therefore requires a full CA rotation — create a new CA, re-sign all
# nodes, then re-import the new secrets into SOPS. This script encapsulates the
# cert side so the rotation is repeatable instead of a hand-typed session.
#
# For adding a SINGLE new host, do NOT run this: sign one cert against the
# existing CA and import it (see hosts/README.md).
#
# Passphrase handling: the CA and node private keys are encrypted with a
# per-directory passphrase (like the original `~/.nebula-ca`). The passphrase is
# generated on first run and stored (chmod 600) in `$CA_DIR/passphrase`; it is
# fed to nebula-cert on a pseudo-tty so the interactive prompts are satisfied.
#
# SOPS re-import is a SEPARATE step because re-encrypting secrets/hosts/*.yaml
# requires the offline MASTER age key (see scripts/nebula-import-secrets.sh):
#
#   SOPS_AGE_KEY_FILE=/path/to/master-age-key.txt \
#     bash scripts/nebula-import-secrets.sh "$CA_DIR"
#
# Usage:
#   bash scripts/nebula-rotate-ca.sh [CA_DIR] [--prefix 10.0.0]
#
#   CA_DIR     directory where the new CA + node certs are written
#              (default: ~/.nebula-ca-<prefix, dots->hyphens>)
#   --prefix   first three octets of the new overlay subnet (default 10.0.0)
#
# The node list comes from scripts/nebula-lib.sh (FLEET).
#
# Idempotent: re-running overwrites the CA directory (and reuses the passphrase
# if one already exists there).
#
set -euo pipefail

# shellcheck disable=SC1091 # nebula-lib.sh is followed via -x (see dev.nix)
# shellcheck source=nebula-lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/nebula-lib.sh"

CA_NAME="t3u-home-ca"
DURATION="8760h" # 1y, matches the existing CA convention

# Union of every group used in the fleet; the CA must permit all of them.
CA_GROUPS="$(for entry in "${FLEET[@]}"; do
  IFS='|' read -r _ _ groups <<< "$entry"
  tr ',' '\n' <<< "$groups"
done | sort -u | paste -sd, -)"

# --- arg parsing -----------------------------------------------------------
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

# --- passphrase (generate once, reuse on re-run) ---------------------------
if [[ ! -f passphrase ]]; then
  head -c 24 /dev/urandom | base64 > passphrase
fi
chmod 600 passphrase
PF="$(cat passphrase)"

# Run a nebula-cert command via `nix shell`, feeding the passphrase on a pty.
run_nebula() {
  script -qec "nix shell nixpkgs#nebula -c $*" /dev/null <<EOF
$PF
EOF
}

# --- CA --------------------------------------------------------------------
echo "== creating CA =="
run_nebula nebula-cert ca \
  -name "$CA_NAME" \
  -networks "$SUBNET" \
  -groups "$CA_GROUPS" \
  -duration "$DURATION" \
  -encrypt \
  -out-crt ca.crt \
  -out-key ca.key

# --- sign every node --------------------------------------------------------
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