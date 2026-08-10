#!/usr/bin/env bash
# build-vps-iso.sh - Build the ConoHa VPS installer ISO with "automatic temporary password issuance"
#
# Usage:
#   ./hosts/torii-chan/build-vps-iso.sh
#
# Behavior:
#   1. Randomly generate a temporary password for the live environment (ISO)
#   2. Hash it with SHA-512 and bake it into the ISO via environment variables in an --impure build
#   3. Save the temporary password to result-iso-temp-password.txt (0600) and display it
#
# The temporary password is only valid for root / t3u in the live environment (while the ISO is running).
# After installation, the production system switches to the SOPS-managed password.
#
# Notes:
#   - Because this script bakes a temporary password into the build, it uses --impure (non-reproducible).
#     For a reproducible normal build: nix build .#torii-chan-vps-iso -o result-iso
#   - If no password is needed (SSH key only), a normal build is sufficient.
set -euo pipefail

cd "$(dirname "$0")/../.."

# 1. Generate a temporary password (16 alphanumeric characters. Since SSH uses keys only, mainly for the VNC console)
TEMP_PASSWORD="[redacted]"
[ -n "${TEMP_PASSWORD}" ] || TEMP_PASSWORD="[redacted]"

# 2. Hash with SHA-512 (openssl passwd -6 uses a random salt)
TEMP_PASSWORD_HASH="[redacted]"

# 3. Save the temporary password to a file (permission 0600)
PASSWORD_FILE="[redacted]"
umask 077
printf 'Temporary password (for root / t3u in the live environment): %s\n' "${TEMP_PASSWORD}" > "${PASSWORD_FILE}"
printf 'Keep this file safe even after the ISO build completes, and delete it once no longer needed.\n' >> "${PASSWORD_FILE}"

# 4. Build the ISO (pass the temporary password hash via an environment variable)
echo "==> Temporary password issued: ${TEMP_PASSWORD} (saved to ${PASSWORD_FILE})"
echo "==> Starting ISO build (--impure)..."
TORII_INSTALLER_TEMP_PASSWORD_HASH="[redacted]"
  nix build --impure .#torii-chan-vps-iso -o result-iso

echo "==> Build complete"
ls -lh result-iso/iso/
echo "Check the temporary password: ${PASSWORD_FILE}"