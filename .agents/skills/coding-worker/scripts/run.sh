#!/usr/bin/env bash
set -euo pipefail

ORIG_UMASK="$(umask)"
umask 077

export __CODING_WORKER_DEPTH=$(( ${__CODING_WORKER_DEPTH:-0} + 1 ))
if [ "$__CODING_WORKER_DEPTH" -ge 2 ]; then
  echo "ERROR: coding-worker recursion limit exceeded (depth: $__CODING_WORKER_DEPTH)" >&2
  exit 1
fi

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

if [ "$READ_ONLY" = "1" ] && [ "$WORKER" != "pi" ]; then
  echo "ERROR: Read-only enforcement is only supported for worker=pi" >&2
  exit 1
fi

if [ "$WORKER" = "pi" ] && ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: worker=pi requires jq for JSON event streaming" >&2
  exit 1
fi

STATE_DIR=".agents/skills/coding-worker/.state"
mkdir -p "$STATE_DIR"
chmod 700 "$STATE_DIR" 2>/dev/null || true
LAST_SESSION_FILE="$STATE_DIR/last-session-$WORKER"

TASK_SESSION_FILE=""
if [ -n "${TASK_ID:-}" ]; then
  TASK_SAFE_ID="$(printf '%s' "$TASK_ID" | tr -c 'a-zA-Z0-9._-' '_')"
  TASK_SESSION_FILE="$STATE_DIR/session-$WORKER-$TASK_SAFE_ID"
fi

CONTINUE_FLAG="${CONTINUE:-0}"
SESSION_ID=""
IS_RESUMED=0

# Read-only runs never resume or persist a session.
if [ "$READ_ONLY" != "1" ]; then
  if [ "$CONTINUE_FLAG" = "1" ] && [ -f "$LAST_SESSION_FILE" ]; then
    SESSION_ID="$(cat "$LAST_SESSION_FILE")"
    IS_RESUMED=1
  elif [ -n "$TASK_SESSION_FILE" ] && [ -f "$TASK_SESSION_FILE" ]; then
    SESSION_ID="$(cat "$TASK_SESSION_FILE")"
    IS_RESUMED=1
  elif [ -n "${TASK_ID:-}" ]; then
    if [ "$WORKER" = "pi" ]; then
      SESSION_ID="$TASK_ID"
    else
      # For dsh and codewhale, unknown session IDs cause errors; start fresh.
      SESSION_ID=""
    fi
  fi
fi

EXTRA_ARGS=()
if [ -n "${EXTRA_FLAGS:-}" ]; then
  # shellcheck disable=SC2206
  EXTRA_ARGS=($EXTRA_FLAGS)
fi

tree_fingerprint() {
  git rev-parse HEAD 2>/dev/null || true
  git status --porcelain
  git diff
  git diff --cached
  git ls-files --others --exclude-standard
}

LOG_FILE="$(mktemp /tmp/coding-worker-XXXXXX.log)"
RESP_FILE="$(mktemp /tmp/coding-worker-resp-XXXXXX.log)"
trap 'rm -f "${RESP_FILE:-}"' EXIT

{
  echo "worker: $WORKER"
  if [ "$READ_ONLY" = "1" ]; then
    echo "mode: read-only"
  fi
  echo "prompt: $PROMPT"
  if [ -n "$SESSION_ID" ]; then
    echo "session: $SESSION_ID"
  fi
} >> "$LOG_FILE"

stream_pi_events() {
  local line progress_line assistant_text
  while IFS= read -r line || [ -n "$line" ]; do
    printf '%s\n' "$line" >> "$LOG_FILE"

    progress_line="$(printf '%s' "$line" | jq -r '
      select(.type == "tool_execution_start")
      | .toolName as $t
      | (.args // {}) as $a
      | (if $t == "bash" then ($a.command // "")
         elif $t == "read" or $t == "edit" or $t == "write" then ($a.file_path // $a.path // "")
         else ((($a | to_entries
                 | map(select(.value | type == "string" or type == "number" or type == "boolean"))
                 | first) // null)
               | if . == null then "" else "\(.key)=\(.value)" end)
         end) as $target
      | (if $t == "bash" and ($target | length) > 60 then $target[0:60] + "..." else $target end) as $shown
      | "[pi] tool: \($t) (\($shown))"
    ' 2>/dev/null)" || true
    if [ -n "$progress_line" ]; then
      printf '%s\n' "$progress_line" >&2
    fi

    assistant_text="$(printf '%s' "$line" | jq -r '
      select(.type == "message_end" and .message.role == "assistant")
      | [.message.content[]? | select(.type == "text") | .text]
      | join("\n")
    ' 2>/dev/null)" || true
    if [ -n "$assistant_text" ]; then
      printf '%s\n' "$assistant_text" > "$RESP_FILE"
    fi
  done
}

PRE_FINGERPRINT=""
if [ "$READ_ONLY" = "1" ]; then
  PRE_FINGERPRINT="$(tree_fingerprint)"
fi

umask "$ORIG_UMASK"
set +e

case "$WORKER" in
  pi)
    PI_ARGS=("--mode" "json")
    if [ "$READ_ONLY" = "1" ]; then
      PI_ARGS+=("--tools" "read,bash,grep,find,ls" "--exclude-tools" "edit,write" "--no-session" "--no-mcp")
    elif [ -n "$SESSION_ID" ]; then
      PI_ARGS+=("--session-id" "$SESSION_ID")
    elif [ "$CONTINUE_FLAG" = "1" ]; then
      PI_ARGS+=("--continue")
    else
      SESSION_ID="task-$(date +%Y%m%d-%H%M%S)-$RANDOM"
      PI_ARGS+=("--session-id" "$SESSION_ID")
    fi

    pi "${PI_ARGS[@]}" "${EXTRA_ARGS[@]}" -- "$PROMPT" < /dev/null 2>> "$LOG_FILE" | stream_pi_events
    EXIT_CODE=${PIPESTATUS[0]}
    ;;

  dsh)
    DSH_ARGS=()
    if [ -n "$SESSION_ID" ] && { [ "$IS_RESUMED" = "1" ] || [ "$CONTINUE_FLAG" = "1" ]; }; then
      DSH_ARGS+=("--session-id" "$SESSION_ID")
    fi

    dsh headless "${DSH_ARGS[@]}" "${EXTRA_ARGS[@]}" -- "$PROMPT" < /dev/null > "$RESP_FILE" 2>> "$LOG_FILE"
    EXIT_CODE=$?

    EXTRACTED_ID="$(grep -hoE 'session-[0-9a-f-]+' "$RESP_FILE" "$LOG_FILE" 2>/dev/null | head -n 1 || true)"
    if [ -n "$EXTRACTED_ID" ]; then
      SESSION_ID="$EXTRACTED_ID"
    fi
    ;;

  codewhale)
    CW_ARGS=("--auto")
    if [ -n "$SESSION_ID" ] && { [ "$IS_RESUMED" = "1" ] || [ "$CONTINUE_FLAG" = "1" ]; }; then
      CW_ARGS+=("--session-id" "$SESSION_ID")
    elif [ "$CONTINUE_FLAG" = "1" ]; then
      CW_ARGS+=("--continue")
    fi

    codewhale exec "${CW_ARGS[@]}" "${EXTRA_ARGS[@]}" -- "$PROMPT" < /dev/null > "$RESP_FILE" 2>> "$LOG_FILE"
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
  if [ -n "$TASK_SESSION_FILE" ]; then
    echo "$SESSION_ID" > "$TASK_SESSION_FILE"
    chmod 600 "$TASK_SESSION_FILE" 2>/dev/null || true
  fi
fi

if [ -s "$RESP_FILE" ]; then
  {
    echo ""
    echo "[response]"
    cat "$RESP_FILE"
  } >> "$LOG_FILE"
fi

if [ "$READ_ONLY" = "1" ]; then
  POST_FINGERPRINT="$(tree_fingerprint)"
  if [ "$PRE_FINGERPRINT" != "$POST_FINGERPRINT" ]; then
    echo "ERROR: Working tree was modified during read-only run!" >&2
    diff -u <(printf '%s\n' "$PRE_FINGERPRINT") <(printf '%s\n' "$POST_FINGERPRINT") >&2 || true
    exit 3
  fi
fi

if [ -n "$SESSION_ID" ]; then
  echo "worker: $WORKER (session: $SESSION_ID, exit: $EXIT_CODE)"
else
  echo "worker: $WORKER (exit: $EXIT_CODE)"
fi
echo "log: $LOG_FILE"

echo ""
echo "[response]"
if [ -s "$RESP_FILE" ]; then
  cat "$RESP_FILE"
else
  echo "(no response)"
fi

echo ""
echo "[status]"
MODIFIED="$(git status --short 2>/dev/null || true)"
if [ -n "$MODIFIED" ]; then
  printf '%s\n' "$MODIFIED"
else
  echo "  (clean)"
fi

echo ""
echo "[stat]"
DIFF_STAT="$(git diff --stat 2>/dev/null || true)"
if [ -n "$DIFF_STAT" ]; then
  printf '%s\n' "$DIFF_STAT"
else
  echo "  (no diff)"
fi

if [ "$EXIT_CODE" -ne 0 ]; then
  echo ""
  echo "[error]"
  tail -n 20 "$LOG_FILE"
fi

exit "$EXIT_CODE"
