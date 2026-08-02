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
#   CONOHAVPS_WAIT_TIMEOUT  状態遷移の最大待機秒数（デフォルト 600）
#   （CONOHAVPS_REGION 省略時は c3j1。SOPS からの注入例は ../README.md 参照）
#
# 依存: curl, jq
set -euo pipefail

REGION="${CONOHAVPS_REGION:-c3j1}"
WAIT_TIMEOUT="${CONOHAVPS_WAIT_TIMEOUT:-600}"
WAIT_INTERVAL=10
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
# 戻り値: サーバー状態（.server.status）。詳細は server_details で取得
server_status() {
  local token="$1" id="$2"
  curl -sS --max-time 30 "${COMPUTE}/servers/${id}" -H "X-Auth-Token: ${token}" |
    jq -r '.server.status'
}

# --- サーバー詳細取得（状態遷移待ち・診断用） ---------------------------------
server_details() {
  local token="$1" id="$2"
  curl -sS --max-time 30 "${COMPUTE}/servers/${id}" -H "X-Auth-Token: ${token}"
}

# --- サーバー状態をポーリングして指定状態を待つ ------------------------------
wait_status() {
  local token="$1" id="$2" want="$3" label="$4"
  local status="" elapsed=0
  echo "  waiting for ${label} ..."
  while [ "${elapsed}" -lt "${WAIT_TIMEOUT}" ]; do
    status=$(server_status "$token" "$id")
    if [ "$status" = "$want" ]; then
      echo "  OK: ${status}"
      return 0
    fi
    sleep "${WAIT_INTERVAL}"
    elapsed=$((elapsed + WAIT_INTERVAL))
  done
  echo "ERROR: timeout waiting for ${want} (last status: ${status})" >&2
  echo "HINT: 現在のサーバー状態を確認: $0 status ${id}" >&2
  return 1
}

# --- サーバーアクション実行 ---------------------------------------------------
# 成功時: HTTP コードを出力。失敗時（4xx/5xx）: レスポンスボディを表示して終了
server_action() {
  local token="$1" id="$2" body="$3"
  local code response
  response=$(curl -sS --max-time 60 -w "\n%{http_code}" -X POST \
    -H "Content-Type: application/json" -H "X-Auth-Token: ${token}" \
    -d "$body" "${COMPUTE}/servers/${id}/action")
  code=$(printf '%s' "${response}" | tail -1)
  if [ "${code}" -ge 400 ] 2>/dev/null; then
    # エラーレスポンスの本文を表示（改行区切りを除去）
    printf '  API error (HTTP %s): %s\n' "${code}" \
      "$(printf '%s' "${response}" | sed '$d' | tr -d '\n' | head -c 500)" >&2
    return 1
  fi
  printf '%s' "${code}"
}

# --- ISO イメージ作成（queued 状態で作成され ID が返る） ----------------------
create_iso_image() {
  local token="$1" name="$2"
  local response
  response=$(curl -sS --max-time 30 -w "\n%{http_code}" -X POST \
    -H "Content-Type: application/json" -H "X-Auth-Token: ${token}" \
    -d "{\"name\":\"${name}\",\"disk_format\":\"iso\",\"hw_rescue_bus\":\"ide\",\"hw_rescue_device\":\"cdrom\",\"container_format\":\"bare\"}" \
    "${IMAGE}/images")
  code=$(printf '%s' "${response}" | tail -1)
  if [ "${code}" != "201" ]; then
    printf 'ERROR: ISO イメージ作成失敗 (HTTP %s): %s\n' "${code}" \
      "$(printf '%s' "${response}" | sed '$d' | tr -d '\n' | head -c 500)" >&2
    return 1
  fi
  printf '%s' "${response}" | sed '$d' | jq -r '.id'
}

# --- ISO ファイル本体のアップロード（204 で完了） -----------------------------
upload_iso() {
  local token="$1" image_id="$2" file="$3"
  curl -sS --max-time 600 -o /dev/null -w "%{http_code}" -X PUT \
    -H "Content-Type: application/octet-stream" -H "X-Auth-Token: ${token}" \
    --data-binary "@${file}" "${IMAGE}/images/${image_id}/file"
}

# --- サーバーを SHUTOFF にする（冪等: 既に停止中なら 409 を許容） -------------
stop_server() {
  local token="$1" id="$2"
  echo "==> サーバー停止"
  if ! code=$(server_action "$token" "$id" '{"os-stop":null}'); then
    return 1
  fi
  case "${code}" in
    202) wait_status "$token" "$id" "SHUTOFF" "shutdown" ;;
    409) echo "  (すでに SHUTOFF のためスキップ)"; return 0 ;;
    *) echo "ERROR: os-stop 失敗 (HTTP ${code})" >&2; return 1 ;;
  esac
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
    if ! iso_id=$(create_iso_image "$token" "$iso_name"); then
      echo "ERROR: ISO イメージ作成に失敗しました" >&2
      exit 1
    fi
    echo "  image_id=${iso_id}"

    echo "==> ISO アップロード (${iso_file})"
    code=$(upload_iso "$token" "$iso_id" "${iso_file}")
    [ "${code}" = "204" ] || { echo "ERROR: ISO アップロード失敗 (HTTP ${code})" >&2; exit 1; }
    echo "  OK: 204"

    if ! stop_server "$token" "$instance_id"; then
      echo "ERROR: サーバーを停止できませんでした" >&2
      exit 1
    fi

    echo "==> ISO 挿入（rescue）"
    # rescue 実行: サーバーは SHUTOFF 状態でなければならない
    rescue_code=0
    code=$(server_action "$token" "$instance_id" "{\"rescue\":{\"rescue_image_ref\":\"${iso_id}\"}}") || rescue_code=$?
    if [ "${rescue_code}" -ne 0 ]; then
      # エラーレスポンスの詳細を表示して終了（既に rescue 中の場合はメッセージで判別可能）
      echo "ERROR: rescue に失敗しました。サーバー状態を確認してください。" >&2
      echo "HINT: 既に rescue モードの場合は先に eject してください: $0 eject ${instance_id}" >&2
      exit 1
    fi
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

    if ! stop_server "$token" "$instance_id"; then
      echo "ERROR: サーバーを停止できませんでした" >&2
      exit 1
    fi

    echo "==> ISO 排出（unrescue）"
    if ! code=$(server_action "$token" "$instance_id" '{"unrescue":null}'); then
      echo "ERROR: unrescue に失敗しました（rescue モードでない可能性）。" >&2
      echo "HINT: $0 status ${instance_id} でサーバー状態を確認してください。" >&2
      exit 1
    fi
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
    server_details "$token" "$2" | jq '.server | {id, name, status, "vm_state": .["OS-EXT-STS:vm_state"], "task_state": .["OS-EXT-STS:task_state"], addresses, created, updated}'
    ;;

  *)
    echo "usage: $0 {install|eject|status} ..." >&2
    exit 1
    ;;
esac
