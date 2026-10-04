#!/usr/bin/env bash
set -euo pipefail

# Helper script for delegating tasks to Codewhale with DeepSeek.
# Usage: ./run.sh "<prompt>"
# Environment variables:
#   CODEPROVIDER (default: deepseek)
#   CODEMODEL    (default: deepseek-flash)
#   EXTRA_FLAGS  (optional extra flags before exec, e.g. --verbosity concise)
#   CONTINUE     (set to 1 to continue previous session)

if [ $# -eq 0 ]; then
  echo "Usage: $0 \"<task description in English>\"" >&2
  exit 1
fi

PROMPT="$1"
PROVIDER="${CODEPROVIDER:-deepseek}"
MODEL="${CODEMODEL:-deepseek-flash}"
CONTINUE_ARGS=()
if [ "${CONTINUE:-0}" = "1" ]; then
  CONTINUE_ARGS+=("--continue")
fi

EXTRA_ARGS=()
if [ -n "${EXTRA_FLAGS:-}" ]; then
  # shellcheck disable=SC2206
  EXTRA_ARGS=($EXTRA_FLAGS)
fi

echo "=== Delegating to Codewhale ==="
echo "Provider: $PROVIDER"
echo "Model:    $MODEL"
echo "Prompt:   $PROMPT"
echo "==============================="

# Run codewhale in tool-backed agent mode
codewhale --provider "$PROVIDER" --model "$MODEL" "${EXTRA_ARGS[@]}" exec --auto "${CONTINUE_ARGS[@]}" "$PROMPT"

EXIT_CODE=$?

echo ""
echo "=== Codewhale Run Finished (exit: $EXIT_CODE) ==="
echo "Files modified:"
git status --short || true

exit $EXIT_CODE
