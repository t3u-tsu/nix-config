#!/usr/bin/env bash
set -euo pipefail

ORIG_UMASK="$(umask)"
umask 077

# Helper script for delegating coding tasks to external workers (pi, dsh, codewhale).
# Usage: ./run.sh [--read-only] "<prompt in English>"
# Environment variables:
#   WORKER       (default: pi; options: pi, dsh, codewhale)
#   TASK_ID      (optional task session ID to group turns, e.g. "feat-dns")
#   CONTINUE     (set to 1 to continue previous session)
#   EXTRA_FLAGS  (optional extra flags forwarded to the worker)
#   READ_ONLY    (set to 1 to enforce read-only review mode; same as --read-only)

case "${READ_ONLY:-0}" in
  1 | true | yes) READ_ONLY=1 ;;
  *) READ_ONLY=0 ;;
esac

while [ $# -gt 0 ]; do
  case "$1" in
    --read-only)
      READ_ONLY=1
      shift
      ;;
    --)
      shift
      break
      ;;
    *) break ;;
  esac
done

if [ $# -eq 0 ]; then
  echo "Usage: $0 [--read-only] \"<task description in English>\"" >&2
  exit 1
fi

PROMPT="$1"
WORKER="${WORKER:-pi}"
STATE_DIR=".agents/skills/coding-worker/.state"
mkdir -p "$STATE_DIR"
chmod 700 "$STATE_DIR" 2>/dev/null || true
LAST_SESSION_FILE="$STATE_DIR/last-session-$WORKER"

CONTINUE_FLAG="${CONTINUE:-0}"
SESSION_ID=""

# Read-only runs never resume or persist a session.
if [ "$READ_ONLY" != "1" ]; then
  if [ "$CONTINUE_FLAG" = "1" ] && [ -f "$LAST_SESSION_FILE" ]; then
    SESSION_ID="$(cat "$LAST_SESSION_FILE")"
  elif [ -n "${TASK_ID:-}" ]; then
    SESSION_ID="$TASK_ID"
  fi
fi

EXTRA_ARGS=()
if [ -n "${EXTRA_FLAGS:-}" ]; then
  # shellcheck disable=SC2206
  EXTRA_ARGS=($EXTRA_FLAGS)
fi

tree_fingerprint() {
  git add -N . >/dev/null 2>&1 || true
  git status --porcelain
  git diff
  git diff --cached
}

LOG_FILE="$(mktemp /tmp/coding-worker-XXXXXX.log)"
RESP_FILE="$(mktemp /tmp/coding-worker-resp-XXXXXX.log)"
trap 'rm -f "${RESP_FILE:-}"' EXIT

echo "=== Delegating Task to Worker: $WORKER ==="
if [ "$READ_ONLY" = "1" ]; then
  echo "Mode:       read-only"
fi
echo "Prompt:     $PROMPT"
if [ -n "$SESSION_ID" ]; then
  echo "Session ID: $SESSION_ID (continue: $CONTINUE_FLAG)"
fi
echo "Log file:   $LOG_FILE"
echo "=========================================="

PRE_FINGERPRINT=""
if [ "$READ_ONLY" = "1" ]; then
  PRE_FINGERPRINT="$(tree_fingerprint)"
fi

umask "$ORIG_UMASK"
set +e

case "$WORKER" in
  pi)
    PI_ARGS=("-p")
    if [ "$READ_ONLY" = "1" ]; then
      PI_ARGS+=("--tools" "read,bash,grep,find,ls" "--exclude-tools" "edit,write" "--no-session")
    elif [ -n "$SESSION_ID" ]; then
      PI_ARGS+=("--session-id" "$SESSION_ID")
    elif [ "$CONTINUE_FLAG" = "1" ]; then
      PI_ARGS+=("--continue")
    else
      SESSION_ID="task-$(date +%Y%m%d-%H%M%S)-$RANDOM"
      PI_ARGS+=("--session-id" "$SESSION_ID")
    fi

    pi "${PI_ARGS[@]}" "${EXTRA_ARGS[@]}" -- "$PROMPT" < /dev/null > "$RESP_FILE" 2> "$LOG_FILE"
    EXIT_CODE=$?
    ;;

  dsh)
    DSH_ARGS=()
    if [ -n "$SESSION_ID" ]; then
      DSH_ARGS+=("--session-id" "$SESSION_ID")
    fi

    dsh headless "${DSH_ARGS[@]}" "${EXTRA_ARGS[@]}" -- "$PROMPT" < /dev/null > "$RESP_FILE" 2> "$LOG_FILE"
    EXIT_CODE=$?

    # Extract sessionId if present in output/logs.
    EXTRACTED_ID="$(grep -hoE 'session-[0-9a-f-]+' "$RESP_FILE" "$LOG_FILE" 2>/dev/null | head -n 1 || true)"
    if [ -n "$EXTRACTED_ID" ]; then
      SESSION_ID="$EXTRACTED_ID"
    fi
    ;;

  codewhale)
    CW_ARGS=("--auto")
    if [ -n "$SESSION_ID" ]; then
      CW_ARGS+=("--session-id" "$SESSION_ID")
    elif [ "$CONTINUE_FLAG" = "1" ]; then
      CW_ARGS+=("--continue")
    fi

    codewhale exec "${CW_ARGS[@]}" "${EXTRA_ARGS[@]}" -- "$PROMPT" < /dev/null > "$RESP_FILE" 2> "$LOG_FILE"
    EXIT_CODE=$?

    EXTRACTED_ID="$(awk '/(resumed )?session: [a-f0-9]+/ {for(i=1;i<=NF;i++) if($i ~ /^[a-f0-9]{8}/) id=$i} END {if (id) print id}' "$LOG_FILE" 2>/dev/null || true)"
    if [ -n "$EXTRACTED_ID" ]; then
      SESSION_ID="$EXTRACTED_ID"
    fi
    ;;

  *)
    echo "Unknown worker: $WORKER (supported: pi, dsh, codewhale)" >&2
    exit 1
    ;;
esac

set -e

if [ "$READ_ONLY" != "1" ] && [ -n "$SESSION_ID" ]; then
  echo "$SESSION_ID" > "$LAST_SESSION_FILE"
  chmod 600 "$LAST_SESSION_FILE" 2>/dev/null || true
fi

if [ -s "$RESP_FILE" ]; then
  {
    echo ""
    echo "=== Final Response (stdout) ==="
    cat "$RESP_FILE"
  } >> "$LOG_FILE"
fi

echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
  echo "=== Worker Run Finished (exit: 0) ==="
else
  echo "=== Worker Run Failed (exit: $EXIT_CODE) ==="
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

if [ "$READ_ONLY" = "1" ]; then
  POST_FINGERPRINT="$(tree_fingerprint)"
  if [ "$PRE_FINGERPRINT" != "$POST_FINGERPRINT" ]; then
    echo ""
    echo "ERROR: Working tree was modified during read-only run!" >&2
    diff -u <(printf '%s\n' "$PRE_FINGERPRINT") <(printf '%s\n' "$POST_FINGERPRINT") || true
    exit 3
  fi
fi

echo ""
echo "Files modified:"
MODIFIED="$(git status --short 2>/dev/null || true)"
if [ -n "$MODIFIED" ]; then
  echo "$MODIFIED"
else
  echo "  (no files modified)"
fi

if [ "$READ_ONLY" != "1" ]; then
  echo ""
  echo "To continue this session:"
  echo "  CONTINUE=1 $0 \"<follow-up prompt>\""
  if [ -n "$SESSION_ID" ]; then
    echo "  (or: TASK_ID=\"$SESSION_ID\" CONTINUE=1 $0 \"<follow-up prompt>\")"
  fi
fi

exit "$EXIT_CODE"
