#!/usr/bin/env bash
set -euo pipefail

# Helper script for delegating technical reviews to Codewhale with DeepSeek.
# Usage: ./review.sh "<review task in English>"
# Environment variables:
#   CODEPROVIDER (default: openrouter)
#   CODEMODEL    (default: deepseek/deepseek-v4.1-flash)
#   DIFF_RANGE   (optional git diff range to include in prompt, e.g. "origin/main..HEAD")
#   FILES        (optional space-separated list of target files)
#   CONTINUE     (set to 1 to continue previous session)
#   SESSION      (optional session ID to resume directly)

if [ $# -eq 0 ] && [ -z "${DIFF_RANGE:-}" ] && [ -z "${FILES:-}" ]; then
  echo "Usage: $0 \"<technical review task in English>\"" >&2
  echo "  or: DIFF_RANGE=\"origin/main..HEAD\" $0" >&2
  echo "  or: FILES=\"docs/operations/backup-and-restore.md\" $0" >&2
  exit 1
fi

USER_PROMPT="${1:-Review the specified changes or files for technical correctness.}"
PROVIDER="${CODEPROVIDER:-openrouter}"
MODEL="${CODEMODEL:-@preset/deepseek-v4.1-flash}"

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

CONTEXT=""
if [ -n "${DIFF_RANGE:-}" ]; then
  DIFF_LINES="$(git diff "$DIFF_RANGE" 2>/dev/null | wc -l || echo 0)"
  if [ "$DIFF_LINES" -gt 0 ] && [ "$DIFF_LINES" -lt 300 ]; then
    DIFF_OUTPUT="$(git diff "$DIFF_RANGE" 2>/dev/null || true)"
    CONTEXT="${CONTEXT}
Target git diff ($DIFF_RANGE):
\`\`\`diff
$DIFF_OUTPUT
\`\`\`
"
  else
    DIFF_STAT="$(git diff --stat "$DIFF_RANGE" 2>/dev/null || true)"
    CONTEXT="${CONTEXT}
Target git diff range: $DIFF_RANGE (Total diff lines: $DIFF_LINES)
Files changed (git diff --stat):
$DIFF_STAT

The diff is large. Inspect specific files or sections using:
  git diff $DIFF_RANGE -- <path>
or
  git diff $DIFF_RANGE
"
  fi
fi

if [ -n "${FILES:-}" ]; then
  CONTEXT="${CONTEXT}
Target files to inspect: $FILES
"
fi

SYSTEM_INSTRUCTION="READ-ONLY TECHNICAL REVIEW:
You are acting as a strict technical reviewer for a NixOS / Linux infrastructure repository.
CRITICAL CONSTRAINT: Do NOT edit, create, or delete ANY files. Your task is purely read-only review and analysis.

Task:
$USER_PROMPT
$CONTEXT

Review Criteria:
1. Technical correctness: Verify Nix syntax/options, systemd unit names, paths, Linux commands, and network configurations against the repository and NixOS standards.
2. Potential bugs, edge cases & failure modes: Look for broken commands, permission issues, state mismatches, or missing recovery steps.
3. Security & best practices: Flag hardcoded secrets, unsafe defaults, or improper privilege elevation.
4. Repository consistency: Ensure adherence to repository architecture, flake modules, and existing patterns.

Output Format:
Provide a concise, high-signal Markdown review report:
- Verdict: [APPROVE / REQUEST_CHANGES / COMMENT]
- Summary: 1-2 sentence overview
- Findings:
  - Severity: [Critical / High / Medium / Low / Suggestion]
  - Location: File path and line/section
  - Issue: Clear technical explanation of why it is wrong or risky
  - Suggested Fix: Concrete fix or corrected code/command snippet
If no issues are found, explicitly state why the changes are technically sound."

LOG_FILE="/tmp/codewhale-review-$(date +%Y%m%d-%H%M%S).log"
if [ -e "$LOG_FILE" ]; then
  LOG_FILE="/tmp/codewhale-review-$(date +%Y%m%d-%H%M%S)-$$.log"
fi

RESP_FILE="$(mktemp /tmp/codewhale-review-resp-XXXXXX.log)"
trap 'rm -f "${RESP_FILE:-}"' EXIT

echo "=== Delegating Technical Review to Codewhale ==="
echo "Provider: $PROVIDER"
echo "Model:    $MODEL"
echo "Task:     $USER_PROMPT"
if [ -n "${DIFF_RANGE:-}" ]; then
  echo "Diff:     $DIFF_RANGE"
fi
if [ -n "${FILES:-}" ]; then
  echo "Files:    $FILES"
fi
echo "Log file: $LOG_FILE"
echo "================================================"

set +e
codewhale --provider "$PROVIDER" --model "$MODEL" "${EXTRA_ARGS[@]}" exec --auto "${CONTINUE_ARGS[@]}" "$SYSTEM_INSTRUCTION" < /dev/null > "$RESP_FILE" 2> "$LOG_FILE"
EXIT_CODE=$?
set -e

if [ -s "$RESP_FILE" ]; then
  {
    echo ""
    echo "=== Final Review (stdout) ==="
    cat "$RESP_FILE"
  } >> "$LOG_FILE"
fi

SESSION_ID="$(awk '/(resumed )?session: [a-f0-9]+/ {for(i=1;i<=NF;i++) if($i ~ /^[a-f0-9]{8}/) id=$i} END {if (id) print id}' "$LOG_FILE")"
if [ -z "$SESSION_ID" ]; then
  SESSION_ID="$(codewhale sessions --limit 1 2>/dev/null | awk '/[a-f0-9]{8}/ {for(i=1;i<=NF;i++) if($i ~ /^[a-f0-9]{8}$/) {print $i; exit}}')"
fi

echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
  echo "=== Codewhale Technical Review Finished (exit: 0) ==="
else
  echo "=== Codewhale Technical Review Failed (exit: $EXIT_CODE) ==="
fi

echo "Log:     $LOG_FILE"
if [ -n "$SESSION_ID" ]; then
  echo "Session: $SESSION_ID"
fi

if [ -s "$RESP_FILE" ]; then
  echo ""
  echo "--- Review Report ---"
  cat "$RESP_FILE"
  echo "---------------------"
elif [ "$EXIT_CODE" -ne 0 ]; then
  echo ""
  echo "--- Error Details (from log) ---"
  tail -n 20 "$LOG_FILE"
  echo "--------------------------------"
fi

# Guard against accidental modifications
DIRTY="$(git status --short 2>/dev/null || true)"
if [ -n "$DIRTY" ]; then
  echo ""
  echo "WARNING: Files were modified during review! Review should be read-only." >&2
  echo "$DIRTY" >&2
fi

exit "$EXIT_CODE"
