#!/usr/bin/env bash
set -euo pipefail

# Helper script for delegating tasks to Codewhale with DeepSeek.
# Usage: ./run.sh "<prompt>"
# Environment variables:
#   CODEPROVIDER (default: deepseek)
#   CODEMODEL    (default: deepseek-flash)
#   EXTRA_FLAGS  (optional extra flags before exec, e.g. --verbosity concise)
#   CONTINUE     (set to 1 to continue previous session)
#   SESSION      (optional session ID to resume directly)

if [ $# -eq 0 ]; then
  echo "Usage: $0 \"<task description in English>\"" >&2
  exit 1
fi

PROMPT="$1"
PROVIDER="${CODEPROVIDER:-deepseek}"
MODEL="${CODEMODEL:-deepseek-flash}"

CONTINUE_ARGS=()
if [ -n "${SESSION:-}" ]; then
  CONTINUE_ARGS+=("--resume" "$SESSION")
elif [ "${CONTINUE:-0}" = "1" ]; then
  CONTINUE_ARGS+=("--continue")
fi

EXTRA_ARGS=()
if [ -n "${EXTRA_FLAGS:-}" ]; then
  # shellcheck disable=SC2206
  EXTRA_ARGS=($EXTRA_FLAGS)
fi

LOG_FILE="/tmp/codewhale-$(date +%Y%m%d-%H%M%S).log"
if [ -e "$LOG_FILE" ]; then
  LOG_FILE="/tmp/codewhale-$(date +%Y%m%d-%H%M%S)-$$.log"
fi

RESP_FILE="$(mktemp /tmp/codewhale-resp-XXXXXX.log)"
trap 'rm -f "${RESP_FILE:-}"' EXIT

echo "=== Delegating to Codewhale ==="
echo "Provider: $PROVIDER"
echo "Model:    $MODEL"
echo "Prompt:   $PROMPT"
echo "Log file: $LOG_FILE"
echo "==============================="

set +e
codewhale --provider "$PROVIDER" --model "$MODEL" "${EXTRA_ARGS[@]}" exec --auto "${CONTINUE_ARGS[@]}" "$PROMPT" < /dev/null > "$RESP_FILE" 2> "$LOG_FILE"
EXIT_CODE=$?
set -e

if [ -s "$RESP_FILE" ]; then
  {
    echo ""
    echo "=== Final Response (stdout) ==="
    cat "$RESP_FILE"
  } >> "$LOG_FILE"
fi

SESSION_ID="$(awk '/(resumed )?session: [a-f0-9]+/ {for(i=1;i<=NF;i++) if($i ~ /^[a-f0-9]{8}/) id=$i} END {if (id) print id}' "$LOG_FILE")"
if [ -z "$SESSION_ID" ]; then
  SESSION_ID="$(codewhale sessions --limit 1 2>/dev/null | awk '/[a-f0-9]{8}/ {for(i=1;i<=NF;i++) if($i ~ /^[a-f0-9]{8}$/) {print $i; exit}}')"
fi

echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
  echo "=== Codewhale Run Finished (exit: 0) ==="
else
  echo "=== Codewhale Run Failed (exit: $EXIT_CODE) ==="
fi

echo "Log:     $LOG_FILE"
if [ -n "$SESSION_ID" ]; then
  echo "Session: $SESSION_ID"
fi

if [ -s "$RESP_FILE" ]; then
  echo ""
  echo "--- Model Response ---"
  cat "$RESP_FILE"
  echo "----------------------"
elif [ "$EXIT_CODE" -ne 0 ]; then
  echo ""
  echo "--- Error Details (from log) ---"
  tail -n 20 "$LOG_FILE"
  echo "--------------------------------"
fi

echo ""
echo "Files modified:"
MODIFIED="$(git status --short 2>/dev/null || true)"
if [ -n "$MODIFIED" ]; then
  echo "$MODIFIED"
else
  echo "  (no files modified)"
fi

echo ""
echo "To continue:"
if [ -n "$SESSION_ID" ]; then
  echo "  CONTINUE=1 $0 \"<follow-up prompt>\""
  echo "  (or: codewhale exec --auto --resume \"$SESSION_ID\" \"<follow-up prompt>\")"
else
  echo "  CONTINUE=1 $0 \"<follow-up prompt>\""
fi

exit "$EXIT_CODE"
