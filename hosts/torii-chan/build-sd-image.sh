#!/usr/bin/env bash
# build-sd-image.sh - build the Orange Pi Zero3 installer SD image with an
# auto-issued temporary password (hash baked in via
# TORII_INSTALLER_TEMP_PASSWORD_HASH in an --impure build; plaintext in
# result-sd-temp-password.txt, mode 0600).
# Reproducible build without a password (SSH key only), and always check the
# target device before dd:
#   nix build .#nixosConfigurations.torii-chan-sd-installer.config.system.build.sdImage
set -euo pipefail

cd "$(dirname "$0")/../.."

# 1. Temporary password for provisioning over LAN SSH (16 hex characters).
# TEMP_PASSWORD may be preset in the environment to reuse a known password.
TEMP_PASSWORD="${TEMP_PASSWORD:-}"
[ -n "${TEMP_PASSWORD}" ] || TEMP_PASSWORD="$(openssl rand -hex 8)"

# 2. SHA-512 crypt hash (openssl passwd -6 salts randomly)
TEMP_PASSWORD_HASH="$(openssl passwd -6 "${TEMP_PASSWORD}")"

PASSWORD_FILE="result-sd-temp-password.txt"
umask 077
printf 'Temporary password (installer SD root / t3u): %s\n' "${TEMP_PASSWORD}" > "${PASSWORD_FILE}"
printf 'Keep this file somewhere safe after the build and delete it once it is no longer needed.\n' >> "${PASSWORD_FILE}"

echo "==> Temporary password issued: saved to ${PASSWORD_FILE}"
echo "==> Building SD image (--impure) ..."
TORII_INSTALLER_TEMP_PASSWORD_HASH="${TEMP_PASSWORD_HASH}" \
  nix build --impure .#nixosConfigurations.torii-chan-sd-installer.config.system.build.sdImage \
  -o result-sd-image

echo "==> Build complete"
ls -lh result-sd-image/sd-image/
echo "Check the temporary password at: ${PASSWORD_FILE}"
echo "Flashing example (always verify the device):"
echo "  lsblk -o NAME,SIZE,MODEL"
echo "  sudo dd if=result-sd-image/sd-image/nixos-image-sd-card-*.img of=/dev/sdX bs=4M status=progress conv=fsync"
