#!/usr/bin/env bash
# ConoHa VPS ISO inject / eject (non-interactive) script
#
# Overview:
#   Helper script that inserts a rescue-mode CD-ROM (ISO image) into a VPS
#   created with the ConoHa stock OS (e.g. Debian), boots the NixOS installer,
#   and overwrites the disk with a fresh install.
#   It calls the ConoHa public API directly (the terraform provider has no ISO operations).
#
# Usage:
#   ./nixos-iso.sh install <instance_id> <iso_file>   # create ISO -> upload -> insert -> start
#   ./nixos-iso.sh eject   <instance_id>              # eject ISO (unrescue) -> start
#   ./nixos-iso.sh status  <instance_id>              # check instance status
#
# Environment variables (same as those used by the terraform provider):
#   CONOHAVPS_USER_ID / CONOHAVPS_PASSWORD / CONOHAVPS_TENANT_ID / CONOHAVPS_REGION
#   CONOHAVPS_WAIT_TIMEOUT  max wait seconds for state transitions (default 600)
#   (When CONOHAVPS_REGION is omitted it defaults to c3j1. See ../README.md for SOPS injection examples)
#
# Dependencies: curl, jq
set -euo pipefail

REGION="${CONOHAVPS_REGION:-c3j1}"
WAIT_TIMEOUT="${CONOHAVPS_WAIT_TIMEOUT:-600}"
WAIT_INTERVAL=10
IDENTITY="https://identity.${REGION}.conoha.io/v3"
IMAGE="https://image-service.${REGION}.conoha.io/v2"
COMPUTE="https://compute.${REGION}.conoha.io/v2.1"

: "${CONOHAVPS_USER_ID:?CONOHAVPS_USER_ID is not set}"
: "${CONOHAVPS_PASSWORD:?CONOHAVPS_PASSWORD is not set}"
: "${CONOHAVPS_TENANT_ID:?CONOHAVPS_TENANT_ID is not set}"

# --- Authentication: obtain X-Subject-Token via Identity API v3 -------------------------
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

# --- Get server status: ACTIVE / SHUTOFF / ERROR etc. -------------------------
# Returns: server status (.server.status). Details are fetched via server_details.
server_status() {
  local token="$1" id="$2"
  curl -sS --max-time 30 "${COMPUTE}/servers/${id}" -H "X-Auth-Token: ${token}" |
    jq -r '.server.status'
}

# --- Get server details (for waiting on state transitions / diagnostics) ---------------------------------
server_details() {
  local token="$1" id="$2"
  curl -sS --max-time 30 "${COMPUTE}/servers/${id}" -H "X-Auth-Token: ${token}"
}

# --- Poll server status and wait for a specified state ------------------------------
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
  echo "HINT: check the current server status: $0 status ${id}" >&2
  return 1
}

# --- Execute a server action ---------------------------------------------------
# On success: prints the HTTP code. On failure (4xx/5xx): prints the response body and exits.
server_action() {
  local token="$1" id="$2" body="$3"
  local code response
  response=$(curl -sS --max-time 60 -w "\n%{http_code}" -X POST \
    -H "Content-Type: application/json" -H "X-Auth-Token: ${token}" \
    -d "$body" "${COMPUTE}/servers/${id}/action")
  code=$(printf '%s' "${response}" | tail -1)
  if [ "${code}" -ge 400 ] 2>/dev/null; then
    # Print the error response body (strip line breaks)
    printf '  API error (HTTP %s): %s\n' "${code}" \
      "$(printf '%s' "${response}" | sed '$d' | tr -d '\n' | head -c 500)" >&2
    return 1
  fi
  printf '%s' "${code}"
}

# --- Create the ISO image (created in queued state; the ID is returned) ----------------------
create_iso_image() {
  local token="$1" name="$2"
  local response
  response=$(curl -sS --max-time 30 -w "\n%{http_code}" -X POST \
    -H "Content-Type: application/json" -H "X-Auth-Token: ${token}" \
    -d "{\"name\":\"${name}\",\"disk_format\":\"iso\",\"hw_rescue_bus\":\"ide\",\"hw_rescue_device\":\"cdrom\",\"container_format\":\"bare\"}" \
    "${IMAGE}/images")
  code=$(printf '%s' "${response}" | tail -1)
  if [ "${code}" != "201" ]; then
    printf 'ERROR: ISO image creation failed (HTTP %s): %s\n' "${code}" \
      "$(printf '%s' "${response}" | sed '$d' | tr -d '\n' | head -c 500)" >&2
    return 1
  fi
  printf '%s' "${response}" | sed '$d' | jq -r '.id'
}

# --- Upload the ISO file body (completes with 204) -----------------------------
upload_iso() {
  local token="$1" image_id="$2" file="$3"
  curl -sS --max-time 600 -o /dev/null -w "%{http_code}" -X PUT \
    -H "Content-Type: application/octet-stream" -H "X-Auth-Token: ${token}" \
    --data-binary "@${file}" "${IMAGE}/images/${image_id}/file"
}

# --- Put the server into SHUTOFF (idempotent: 409 is tolerated if already stopped) -------------
stop_server() {
  local token="$1" id="$2"
  echo "==> Stopping server"
  if ! code=$(server_action "$token" "$id" '{"os-stop":null}'); then
    return 1
  fi
  case "${code}" in
    202) wait_status "$token" "$id" "SHUTOFF" "shutdown" ;;
    409) echo "  (already SHUTOFF, skipping)"; return 0 ;;
    *) echo "ERROR: os-stop failed (HTTP ${code})" >&2; return 1 ;;
  esac
}

# --- Main -------------------------------------------------------------------
cmd="${1:-}"
case "${cmd}" in
  install)
    [ $# -eq 3 ] || { echo "usage: $0 install <instance_id> <iso_file>" >&2; exit 1; }
    instance_id="$2"
    iso_file="$3"
    [ -f "${iso_file}" ] || { echo "ERROR: ISO file not found: ${iso_file}" >&2; exit 1; }

    echo "==> Authenticating"
    token=$(get_token)
    [ -n "${token}" ] || { echo "ERROR: failed to obtain token" >&2; exit 1; }

    echo "==> Creating ISO image"
    iso_name="nixos-$(basename "${iso_file}" .iso)-$(date +%Y%m%d%H%M%S)"
    if ! iso_id=$(create_iso_image "$token" "$iso_name"); then
      echo "ERROR: ISO image creation failed" >&2
      exit 1
    fi
    echo "  image_id=${iso_id}"

    echo "==> Uploading ISO (${iso_file})"
    code=$(upload_iso "$token" "$iso_id" "${iso_file}")
    [ "${code}" = "204" ] || { echo "ERROR: ISO upload failed (HTTP ${code})" >&2; exit 1; }
    echo "  OK: 204"

    if ! stop_server "$token" "$instance_id"; then
      echo "ERROR: could not stop the server" >&2
      exit 1
    fi

    echo "==> Inserting ISO (rescue)"
    # rescue run: the server must be in SHUTOFF state
    rescue_code=0
    code=$(server_action "$token" "$instance_id" "{\"rescue\":{\"rescue_image_ref\":\"${iso_id}\"}}") || rescue_code=$?
    if [ "${rescue_code}" -ne 0 ]; then
      # Print the error response details and exit (the message indicates whether rescue mode was already active)
      echo "ERROR: rescue failed. Please check the server status." >&2
      echo "HINT: if already in rescue mode, eject first: $0 eject ${instance_id}" >&2
      exit 1
    fi
    [ "${code}" = "200" ] || { echo "ERROR: rescue failed (HTTP ${code})" >&2; exit 1; }
    echo "  OK: 200 (booting into rescue mode)"

    # Start the server if it is not yet ACTIVE (rescue mode) after the rescue run
    if [ "$(server_status "$token" "$instance_id")" != "ACTIVE" ]; then
      echo "==> Starting server"
      code=$(server_action "$token" "$instance_id" '{"os-start":null}')
      [ "${code}" = "202" ] || { echo "ERROR: os-start failed (HTTP ${code})" >&2; exit 1; }
    fi
    wait_status "$token" "$instance_id" "ACTIVE" "boot from ISO"

    echo ""
    echo "==> Done: booting from ISO. Use the VNC console (ConoHa control panel) to operate the installer."
    echo "    After the installation completes, eject the ISO with ./nixos-iso.sh eject ${instance_id}."
    ;;

  eject)
    [ $# -eq 2 ] || { echo "usage: $0 eject <instance_id>" >&2; exit 1; }
    instance_id="$2"

    echo "==> Authenticating"
    token=$(get_token)
    [ -n "${token}" ] || { echo "ERROR: failed to obtain token" >&2; exit 1; }

    if ! stop_server "$token" "$instance_id"; then
      echo "ERROR: could not stop the server" >&2
      exit 1
    fi

    echo "==> Ejecting ISO (unrescue)"
    if ! code=$(server_action "$token" "$instance_id" '{"unrescue":null}'); then
      echo "ERROR: unrescue failed (the server may not be in rescue mode)." >&2
      echo "HINT: check the server status with $0 status ${instance_id}." >&2
      exit 1
    fi
    [ "${code}" = "200" ] || { echo "ERROR: unrescue failed (HTTP ${code})" >&2; exit 1; }
    echo "  OK: 200"

    echo "==> Starting server"
    code=$(server_action "$token" "$instance_id" '{"os-start":null}')
    [ "${code}" = "202" ] || { echo "ERROR: os-start failed (HTTP ${code})" >&2; exit 1; }
    wait_status "$token" "$instance_id" "ACTIVE" "boot from disk"

    echo "==> Done: back to normal boot."
    ;;

  status)
    [ $# -eq 2 ] || { echo "usage: $0 status <instance_id>" >&2; exit 1; }
    token=$(get_token)
    [ -n "${token}" ] || { echo "ERROR: failed to obtain token" >&2; exit 1; }
    server_details "$token" "$2" | jq '.server | {id, name, status, "vm_state": .["OS-EXT-STS:vm_state"], "task_state": .["OS-EXT-STS:task_state"], addresses, created, updated}'
    ;;

  *)
    echo "usage: $0 {install|eject|status} ..." >&2
    exit 1
    ;;
esac
