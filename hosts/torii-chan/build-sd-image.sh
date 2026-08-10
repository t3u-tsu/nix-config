#!/usr/bin/env bash
# build-sd-image.sh - Builds an SD installer image for the Orange Pi Zero3 with
# auto-issued temporary passwords
#
# Usage:
#   ./hosts/torii-chan/build-sd-image.sh
#
# Behavior:
#   1. Randomly generates a temporary password for the live environment (SD boot)
#   2. Hashes it with SHA-512 and bakes it into the image via an environment
#      variable in an --impure build
#   3. Saves the temporary password to result-sd-temp-password.txt (0600) and prints it
#
# The temporary password is only valid for root / t3u in the installer (while the
# SD is booted). After going to production (nixos-rebuild switch --flake
# .#torii-chan-sd / torii-chan-hdd), the SOPS-managed password takes over.
#
# Notes:
#   - Because this script bakes in a temporary password, its build is --impure
#     (non-reproducible). A reproducible normal build:
#     nix build .#nixosConfigurations.torii-chan-sd-installer.config.system.build.sdImage
#   - If no password is needed (SSH key only), a normal build is sufficient.
#   - Always double-check the target device (e.g. /dev/sdX) before running dd.
set -euo pipefail

cd "$(dirname "$0")/../.."

# 1. Generate the temporary password (16 alphanumeric characters, for provisioning over LAN SSH)
TEMP_PASSWORD="${TEMP_PASSWORD:-}"
[ -n "${TEMP_PASSWORD}" ] || TEMP_PASSWORD="$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 16)"

# 2. Hash with SHA-512 (openssl passwd -6 uses a random salt)
TEMP_PASSWORD_HASH="$(openssl passwd -6 "${TEMP_PASSWORD}")"

# 3. Save the temporary password to a file (mode 0600)
PASSWORD_FILE="result-sd-temp-password.txt"
umask 077
printf 'Temporary password (installer SD root / t3u): %s\n' "${TEMP_PASSWORD}" > "${PASSWORD_FILE}"
printf 'Keep this file somewhere safe after the build and delete it once it is no longer needed.\n' >> "${PASSWORD_FILE}"

# 4. Build the image (passing the temporary password hash via environment variable)
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
