#!/usr/bin/env bash
# init-host-key.sh - Thin wrapper for init-host-key.ysh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YSH_SCRIPT="${SCRIPT_DIR}/init-host-key.ysh"

if [ ! -f "${YSH_SCRIPT}" ]; then
  echo "ERROR: ${YSH_SCRIPT} not found" >&2
  exit 1
fi

if command -v ysh >/dev/null 2>&1; then
  exec ysh "${YSH_SCRIPT}" "$@"
fi

if ! command -v nix-shell >/dev/null 2>&1; then
  echo "ERROR: ysh and nix-shell are missing." >&2
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
exec nix-shell -p oils-for-unix --run "${cmd}"
