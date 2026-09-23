#!/usr/bin/env bash
# build-vps-iso.sh - build the ConoHa VPS installer ISO with an auto-issued
# temporary password (hash baked in via TORII_INSTALLER_TEMP_PASSWORD_HASH in an
# --impure build; plaintext in result-iso-temp-password.txt, mode 0600).
# Reproducible build without a password (SSH key only):
#   nix build .#torii-chan-vps-iso -o result-iso
set -euo pipefail

cd "$(dirname "$0")/../.."

# 1. Temporary password for the live environment (VNC console; SSH is key-only)
TEMP_PASSWORD="[redacted]"
[ -n "${TEMP_PASSWORD}" ] || TEMP_PASSWORD="[redacted]"


PASSWORD_FILE="[redacted]"
umask 077
printf 'Temporary password (for root / t3u in the live environment): %s\n' "${TEMP_PASSWORD}" > "${PASSWORD_FILE}"
printf 'Keep this file safe even after the ISO build completes, and delete it once no longer needed.\n' >> "${PASSWORD_FILE}"

echo "==> Temporary password issued: saved to ${PASSWORD_FILE}"
echo "==> Starting ISO build (--impure)..."
export TORII_INSTALLER_TEMP_PASSWORD_HASH="[redacted]"
  nix build --impure .#torii-chan-vps-iso -o result-iso

echo "==> Build complete"
ls -lh result-iso/iso/
echo "Check the temporary password: ${PASSWORD_FILE}"
