#!/usr/bin/env bash
#
# scripts/set-host-password.sh
#
# Create/set the user (t3u) and root password hashes in
# secrets/hosts/<hostname>.yaml via sops, from interactively entered
# passwords. Passwords are read with read -s (not echoed, not in argv/history)
# and converted to a sha-512 crypt hash with mkpasswd.
#
# Usage:
#   bash scripts/set-host-password.sh <hostname>
#
#   <hostname> is the hosts/<name>/ dir (SOPS key prefix is derived from it).
#   mkpasswd must be on PATH (nix shell nixpkgs#mkpasswd -c bash "$0" ... ).
#
# Requires the repo's .sops.yaml creation rules to cover secrets/hosts/<host>.
# The user/root password hash keys are `<hostkey>_t3u_password_hash` and
# `<hostkey>_root_password_hash` where <hostkey> is the lowercased hostname
# with '-' -> '_'.
set -euo pipefail

host="${1:?usage: $0 <hostname>}"
hostkey="$(printf '%s' "$host" | tr '[:upper:]' '[:lower:]' | tr '-' '_')"
file="secrets/hosts/${host}.yaml"

if ! command -v mkpasswd >/dev/null 2>&1; then
  echo "ERROR: mkpasswd not found. Run via: nix shell nixpkgs#mkpasswd -c bash $0 x1c7" >&2
  exit 1
fi

read -rsp "password for t3u: " upass
echo
read -rsp "password for root: " rpass
echo
[[ -n "$upass" && -n "$rpass" ]] || { echo "ERROR: empty password" >&2; exit 1; }

us=$(mkpasswd -m sha-512 "$upass")
rs=$(mkpasswd -m sha-512 "$rpass")
unset upass rpass

sops set "$file" "[\"${hostkey}_t3u_password_hash\"]" "\"$us\""
sops set "$file" "[\"${hostkey}_root_password_hash\"]" "\"$rs\""
unset us rs

echo "OK: set ${hostkey}_t3u_password_hash / ${hostkey}_root_password_hash in ${file}"
