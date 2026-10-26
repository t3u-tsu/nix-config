#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YSH_SCRIPT="${SCRIPT_DIR}/init-host-key.ysh"

if [ ! -f "${YSH_SCRIPT}" ]; then
  echo "ERROR: ${YSH_SCRIPT} not found" >&2
  exit 1
fi

missing_pkgs=()
command -v ysh >/dev/null 2>&1 || missing_pkgs+=("oils-for-unix")
if ! command -v ssh-keygen >/dev/null 2>&1; then
  missing_pkgs+=("openssh")
fi

if [ ${#missing_pkgs[@]} -eq 0 ]; then
  exec ysh "${YSH_SCRIPT}" "$@"
fi

if ! command -v nix-shell >/dev/null 2>&1; then
  echo "ERROR: nix-shell is required to install ${missing_pkgs[*]}." >&2
  exit 1
fi

if [ -z "${NIX_PATH:-}" ]; then
  for p in /nix/var/nix/profiles/per-user/root/channels/nixos \
           /nix/var/nix/profiles/per-user/root/channels \
           /root/.nix-defexpr/channels/nixos \
           /root/.nix-defexpr/channels; do
    if [ -e "$p" ]; then
      export NIX_PATH="nixpkgs=${p}"
      break
    fi
  done
fi

cmd="$(printf '%q ' ysh "${YSH_SCRIPT}" "$@")"
exec nix-shell -p "${missing_pkgs[@]}" --run "${cmd}"
