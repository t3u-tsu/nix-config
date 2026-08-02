#!/usr/bin/env bash
# ConoHa VPS への ISO 注入 / 排出（非対話）スクリプト
#
# 概要:
#   ConoHa 標準 OS（例: Debian）で作成した VPS に、rescue モードの CD-ROM
#   （ISO イメージ）を挿入して NixOS インストーラをブートし、ディスクを
#   上書きインストールするための補助スクリプト。
#   API は ConoHa 公開 API を直接叩く（terraform プロバイダには ISO 操作が無いため）。
#
# 使い方:
#   ./nixos-iso.sh install <instance_id> <iso_file>   # ISO 作成→アップロード→挿入→起動
#   ./nixos-iso.sh eject   <instance_id>              # ISO 排出（unrescue）→起動
#   ./nixos-iso.sh status  <instance_id>              # インスタンス状態の確認
#
# 環境変数（terraform プロバイダと同じものを使用）:
#   CONOHAVPS_USER_ID / CONOHAVPS_PASSWORD / CONOHAVPS_TENANT_ID / CONOHAVPS_REGION
#   （CONOHAVPS_REGION 省略時は c3j1。SOPS からの注入例は ../README.md 参照）
#
# 依存: curl, jq
set -euo pipefail

REGION="${CONOHAVPS_REGION:-c3j1}"
IDENTITY="https://identity.${REGION}.conoha.io/v3"
IMAGE="https://image-service.${REGION}.conoha.io/v2"
COMPUTE="https://compute.${REGION}.conoha.io/v2.1"

: "${CONOHAVPS_USER_ID:?CONOHAVPS_USER_ID が未設定}"
: "${CONOHAVPS_PASSWORD:?CONOHAVPS_PASSWORD が未設定}"
: "${CONOHAVPS_TENANT_ID:?CONOHAVPS_TENANT_ID が未設定}"

# --- 認証: Identity API v3 で X-Subject-Token を取得 -------------------------
get_token() {
  local body
  body=$(jq -n \
    --arg u "$CONOHAVPS_USER_ID" \
    --arg p "$CONOHAVPS_PASSWORD" \
    --arg t "$CONOHAVPS_TENANT_ID" \
    '{auth:{identity:{methods:["password"],password:{user:{id:$u,password:$p}}},scope:{project:{id:$t}}}}')
  curl -sS --max-time 30 -D - -o /dev/null -X POST \
    -H "Content-Type: application/json" -H "Accept: application/json" \
    -d "$body" "${IDENTITY}/auth/tokens" |
    awk 'tolower($1)=="x-subject-token:"{print $2}' | tr -d '\r'
}

# --- サーバー状態取得: ACTIVE / SHUTOFF / ERROR など -------------------------
server_status() {
  local token="$1" id="$2"
  curl -sS --max-time 30 "${COMPUTE}/servers/${id}" -H "X-Auth-Token: ${token}" |
    jq -r '.server.status'
}

# --- サーバー状態をポーリングして指定状態を待つ ------------------------------
wait_status() {
  local token="$1" id="$2" want="$3" label="$4"
  local status
  echo "  waiting for ${label} ..."
  for _ in $(seq 1 60); do # 最大 10 分
    status=$(server_status "$token" "$id")
    if [ "$status" = "$want" ]; then
      echo "  OK: ${status}"
      return 0
    fi
    sleep 10
  done
  echo "ERROR: timeout waiting for ${want} (last status: ${status})" >&2
  return 1
}

# --- サーバーアクション実行 ---------------------------------------------------
server_action() {
  local token="$1" id="$2" body="$3"
  curl -sS --max-time 60 -o /dev/null -w "%{http_code}" -X POST \
    -H "Content-Type: application/json" -H "X-Auth-Token: ${token}" \
    -d "$body" "${COMPUTE}/servers/${id}/action"
}

# --- ISO イメージ作成（queued 状態で作成され ID が返る） ----------------------
create_iso_image() {
  local token="$1" name="$2"
  curl -sS --max-time 30 -X POST \
    -H "Content-Type: application/json" -H "X-Auth-Token: ${token}" \
    -d "{\"name\":\"${name}\",\"disk_format\":\"iso\",\"hw_rescue_bus\":\"ide\",\"hw_rescue_device\":\"cdrom\",\"container_format\":\"bare\"}" \
    "${IMAGE}/images" | jq -r '.id'
}

# --- ISO ファイル本体のアップロード（204 で完了） -----------------------------
upload_iso() {
  local token="$1" image_id="$2" file="$3"
  curl -sS --max-time 600 -o /dev/null -w "%{http_code}" -X PUT \
    -H "Content-Type: application/octet-stream" -H "X-Auth-Token: ${token}" \
    --data-binary "@${file}" "${IMAGE}/images/${image_id}/file"
}

# --- メイン -------------------------------------------------------------------
cmd="${1:-}"
case "${cmd}" in
  install)
    [ $# -eq 3 ] || { echo "usage: $0 install <instance_id> <iso_file>" >&2; exit 1; }
    instance_id="$2"
    iso_file="$3"
    [ -f "${iso_file}" ] || { echo "ERROR: ISO ファイルが見つかりません: ${iso_file}" >&2; exit 1; }

    echo "==> 認証"
    token=$(get_token)
    [ -n "${token}" ] || { echo "ERROR: トークン取得失敗" >&2; exit 1; }

    echo "==> ISO イメージ作成"
    iso_name="nixos-$(basename "${iso_file}" .iso)-$(date +%Y%m%d%H%M%S)"
    iso_id=$(create_iso_image "$token" "$iso_name")
    echo "  image_id=${iso_id}"

    echo "==> ISO アップロード (${iso_file})"
    code=$(upload_iso "$token" "$iso_id" "${iso_file}")
    [ "${code}" = "204" ] || { echo "ERROR: ISO アップロード失敗 (HTTP ${code})" >&2; exit 1; }
    echo "  OK: 204"

    echo "==> サーバー停止"
    code=$(server_action "$token" "$instance_id" '{"os-stop":null}')
    if [ "${code}" != "202" ] && [ "${code}" != "409" ]; then
      echo "ERROR: os-stop 失敗 (HTTP ${code})" >&2; exit 1
    fi
    wait_status "$token" "$instance_id" "SHUTOFF" "shutdown"

    echo "==> ISO 挿入（rescue）"
    code=$(server_action "$token" "$instance_id" "{\"rescue\":{\"rescue_image_ref\":\"${iso_id}\"}}")
    [ "${code}" = "200" ] || { echo "ERROR: rescue 失敗 (HTTP ${code})" >&2; exit 1; }
    echo "  OK: 200 (rescue モードで起動します)"

    # rescue 実行後に ACTIVE（rescue モード）になっていなければ起動する
    if [ "$(server_status "$token" "$instance_id")" != "ACTIVE" ]; then
      echo "==> サーバー起動"
      code=$(server_action "$token" "$instance_id" '{"os-start":null}')
      [ "${code}" = "202" ] || { echo "ERROR: os-start 失敗 (HTTP ${code})" >&2; exit 1; }
    fi
    wait_status "$token" "$instance_id" "ACTIVE" "boot from ISO"

    echo ""
    echo "==> 完了: ISO からブートします。VNC コンソール（ConoHa コントロールパネル）でインストーラを操作してください。"
    echo "    インストール完了後、./nixos-iso.sh eject ${instance_id} で ISO を排出します。"
    ;;

  eject)
    [ $# -eq 2 ] || { echo "usage: $0 eject <instance_id>" >&2; exit 1; }
    instance_id="$2"

    echo "==> 認証"
    token=$(get_token)
    [ -n "${token}" ] || { echo "ERROR: トークン取得失敗" >&2; exit 1; }

    echo "==> サーバー停止"
    code=$(server_action "$token" "$instance_id" '{"os-stop":null}')
    if [ "${code}" != "202" ] && [ "${code}" != "409" ]; then
      echo "ERROR: os-stop 失敗 (HTTP ${code})" >&2; exit 1
    fi
    wait_status "$token" "$instance_id" "SHUTOFF" "shutdown"

    echo "==> ISO 排出（unrescue）"
    code=$(server_action "$token" "$instance_id" '{"unrescue":null}')
    [ "${code}" = "200" ] || { echo "ERROR: unrescue 失敗 (HTTP ${code})" >&2; exit 1; }
    echo "  OK: 200"

    echo "==> サーバー起動"
    code=$(server_action "$token" "$instance_id" '{"os-start":null}')
    [ "${code}" = "202" ] || { echo "ERROR: os-start 失敗 (HTTP ${code})" >&2; exit 1; }
    wait_status "$token" "$instance_id" "ACTIVE" "boot from disk"

    echo "==> 完了: 通常ブートに戻りました。"
    ;;

  status)
    [ $# -eq 2 ] || { echo "usage: $0 status <instance_id>" >&2; exit 1; }
    token=$(get_token)
    [ -n "${token}" ] || { echo "ERROR: トークン取得失敗" >&2; exit 1; }
    server_status "$token" "$2"
    ;;

  *)
    echo "usage: $0 {install|eject|status} ..." >&2
    exit 1
    ;;
esac
