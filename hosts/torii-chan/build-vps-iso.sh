#!/usr/bin/env bash
# build-vps-iso.sh - ConoHa VPS インストーラ ISO を「一時パスワード自動発行」付きでビルドする
#
# 使い方:
#   ./hosts/torii-chan/build-vps-iso.sh
#
# 動作:
#   1. ライブ環境（ISO）用の一時パスワードをランダム生成
#   2. SHA-512 ハッシュ化し、--impure ビルドで環境変数経由で ISO に焼き込む
#   3. 一時パスワードを result-iso-temp-password.txt（0600）に保存して表示
#
# 一時パスワードはライブ環境（ISO 起動中）の root / t3u でのみ有効。
# インストール後の本番システムは SOPS 管理のパスワードに切り替わる。
#
# 注意:
#   - 本スクリプトのビルドは一時パスワードを焼き込むため --impure（非再現性）になる。
#     再現性のある通常ビルドは: nix build .#torii-chan-vps-iso -o result-iso
#   - パスワード不要（SSH 鍵のみで運用）なら通常ビルドで十分。
set -euo pipefail

cd "$(dirname "$0")/../.."

# 1. 一時パスワードを生成（英数字 16 文字。SSH は鍵のみなので主に VNC コンソール用）
TEMP_PASSWORD="$(openssl rand -base64 12 | tr -dc 'A-Za-z0-9' | head -c 16 || true)"
[ -n "${TEMP_PASSWORD}" ] || TEMP_PASSWORD="conoha$(date +%s)"

# 2. SHA-512 ハッシュ化（openssl passwd -6 はランダムソルト）
TEMP_PASSWORD_HASH="$(openssl passwd -6 "${TEMP_PASSWORD}")"

# 3. 一時パスワードをファイルに保存（権限 0600）
PASSWORD_FILE="result-iso-temp-password.txt"
umask 077
printf '一時パスワード（ライブ環境の root / t3u 用）: %s\n' "${TEMP_PASSWORD}" > "${PASSWORD_FILE}"
printf 'ISO ビルド完了後もこのファイルを安全に保管し、不要になったら削除してください。\n' >> "${PASSWORD_FILE}"

# 4. ISO をビルド（一時パスワードハッシュを環境変数で渡す）
echo "==> 一時パスワードを発行: ${TEMP_PASSWORD}（${PASSWORD_FILE} に保存）"
echo "==> ISO ビルド開始（--impure）..."
TORII_INSTALLER_TEMP_PASSWORD_HASH="${TEMP_PASSWORD_HASH}" \
  nix build --impure .#torii-chan-vps-iso -o result-iso

echo "==> ビルド完了"
ls -lh result-iso/iso/
echo "一時パスワード: ${PASSWORD_FILE} を確認してください"
