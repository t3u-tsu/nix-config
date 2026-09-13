#!/usr/bin/env bash
#
# Usage: SOPS_AGE_KEY_FILE=<master age key> bash scripts/set-host-password.sh <hostname>
#
# <hostname> is a hosts/<name>/ directory; the SOPS keys written are
# <hostkey>_t3u_password_hash and <hostkey>_root_password_hash (<hostkey> =
# lowercased hostname, '-' -> '_'). The master key is needed only when the
# secrets file already exists. mkpasswd, sops and jq must be on PATH:
#   nix shell nixpkgs#mkpasswd nixpkgs#sops nixpkgs#jq -c bash scripts/set-host-password.sh x1c7
set -euo pipefail

host="${1:?usage: $0 <hostname>}"
hostkey="$(printf '%s' "$host" | tr '[:upper:]' '[:lower:]' | tr '-' '_')"
file="secrets/hosts/${host}.yaml"

for tool in mkpasswd sops jq; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "ERROR: $tool not found. Run via: nix shell nixpkgs#mkpasswd nixpkgs#sops nixpkgs#jq -c bash $0 ${host}" >&2
    exit 1
  }
done

read -rsp "password for t3u: " upass
echo
read -rsp "password for root: " rpass
echo
[[ -n "$upass" && -n "$rpass" ]] || { echo "ERROR: empty password" >&2; exit 1; }

# mkpasswd hashes a password passed as an argument, which would expose it in
# /proc/<pid>/cmdline; -s reads it from stdin instead.
us=$(printf '%s\n' "$upass" | mkpasswd -m sha-512 -s)
rs=$(printf '%s\n' "$rpass" | mkpasswd -m sha-512 -s)
unset upass rpass
[[ "$us" == \$6\$* && "$rs" == \$6\$* ]] || { echo "ERROR: mkpasswd returned no sha-512 hash" >&2; exit 1; }

if [[ -f "$file" ]]; then
  # sops set has to decrypt the file to merge the two hashes, and host secrets
  # deliberately exclude the user key, so only the offline master key can do it.
  : "${SOPS_AGE_KEY_FILE:?set SOPS_AGE_KEY_FILE to the master age key that can decrypt $file}"
  sops set "$file" "[\"${hostkey}_t3u_password_hash\"]" "$(jq -Rn --arg v "$us" '$v')"
  sops set "$file" "[\"${hostkey}_root_password_hash\"]" "$(jq -Rn --arg v "$rs" '$v')"
else
  # A new file is encrypted from plaintext, which only needs the public keys.
  # The plaintext lives outside the repo, and --filename-override picks the
  # .sops.yaml creation rule for $file, since rules match on the path.
  plain="$(mktemp)"
  trap 'rm -f "$plain"' EXIT
  printf '%s_t3u_password_hash: "%s"\n%s_root_password_hash: "%s"\n' \
    "$hostkey" "$us" "$hostkey" "$rs" > "$plain"
  sops encrypt --filename-override "$file" --output "$file" "$plain"
fi
unset us rs

echo "OK: set ${hostkey}_t3u_password_hash / ${hostkey}_root_password_hash in ${file}"
