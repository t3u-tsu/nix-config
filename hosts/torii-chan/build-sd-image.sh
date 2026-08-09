#!/usr/bin/env bash
# build-sd-image.sh - Orange Pi Zero3 用 SD インストーライメージを
# 「一時パスワード自動発行」付きでビルドする
#
# 使い方:
#   ./hosts/torii-chan/build-sd-image.sh
#
# 動作:
#   1. ライブ環境（SD 起動中）用の一時パスワードをランダム生成
#   2. SHA-512 ハッシュ化し、--impure ビルドで環境変数経由でイメージに焼き込む
#   3. 一時パスワードを result-sd-temp-password.txt（0600）に保存して表示
#
# 一時パスワードはインストーラ（SD 起動中）の root / t3u でのみ有効。
# 本番化（nixos-rebuild switch --flake .#torii-chan-sd / torii-chan-hdd）後は
# SOPS 管理のパスワードに切り替わる。
#
# 注意:
#   - 本スクリプトのビルドは一時パスワードを焼き込むため --impure（非再現性）になる。
#     再現性のある通常ビルドは: nix build .#nixosConfigurations.torii-chan-sd-installer.config.system.build.sdImage
#   - パスワード不要（SSH 鍵のみで運用）なら通常ビルドで十分。
#   - 書き込み先デバイス（例: /dev/sdX）は必ず確認してから dd すること。
set -euo pipefail

cd "$(dirname "$0")/../.."

# 1. 一時パスワードを生成（英数字 16 文字。LAN 内 SSH でのプロビジョニング用）
TEMP_PASSWORD="${TEMP_PASSWORD:-}"
[ -n "${TEMP_PASSWORD}" ] || TEMP_PASSWORD="$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 16)"

# 2. SHA-512 ハッシュ化（openssl passwd -6 はランダムソルト）
TEMP_PASSWORD_HASH="$(openssl passwd -6 "${TEMP_PASSWORD}")"

# 3. 一時パスワードをファイルに保存（権限 0600）
PASSWORD_FILE="result-sd-temp-password.txt"
umask 077
printf '一時パスワード（インストーラ SD の root / t3u 用）: %s\n' "${TEMP_PASSWORD}" > "${PASSWORD_FILE}"
printf 'ビルド完了後もこのファイルを安全に保管し、不要になったら削除してください。\n' >> "${PASSWORD_FILE}"

# 4. イメージをビルド（一時パスワードハッシュを環境変数で渡す）
echo "==> 一時パスワードを発行: ${PASSWORD_FILE} に保存"
echo "==> SD イメージ ビルド開始（--impure）..."
TORII_INSTALLER_TEMP_PASSWORD_HASH="${TEMP_PASSWORD_HASH}" \
  nix build --impure .#nixosConfigurations.torii-chan-sd-installer.config.system.build.sdImage \
  -o result-sd-image

echo "==> ビルド完了"
ls -lh result-sd-image/sd-image/
echo "一時パスワード: ${PASSWORD_FILE} を確認してください"
echo "書き込み例（デバイスを必ず確認）:"
echo "  lsblk -o NAME,SIZE,MODEL"
echo "  sudo dd if=result-sd-image/sd-image/nixos-image-sd-card-*.img of=/dev/sdX bs=4M status=progress conv=fsync"
