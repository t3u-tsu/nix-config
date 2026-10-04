#!/usr/bin/env bash
set -euo pipefail

# Helper script for inspecting Codewhale providers and models.
# Usage:
#   ./info.sh                  # List authenticated providers & active route
#   ./info.sh models [PROVIDER]# List models for a provider
#   ./info.sh search <KEYWORD> # Search models across authenticated providers
#   ./info.sh resolve          # Show active route resolution details

cmd="${1:-summary}"

get_authenticated_providers() {
  codewhale auth list | awk 'NR>1 && ($3=="yes" || $4=="yes") {print $1}'
}

case "$cmd" in
  summary|"")
    echo "=== Active Route ==="
    codewhale model resolve
    echo ""
    echo "=== Authenticated Providers ==="
    for p in $(get_authenticated_providers); do
      echo "  • $p"
    done
    echo ""
    echo "Usage tips:"
    echo "  $0 models <provider>  # View all models for a provider"
    echo "  $0 search <keyword>   # Search models across providers"
    ;;

  resolve)
    codewhale model resolve
    ;;

  models)
    provider="${2:-}"
    if [ -z "$provider" ]; then
      provider="$(codewhale model resolve | awk -F': ' '$1=="provider" {print $2}')"
    fi
    echo "=== Models for provider: $provider ==="
    codewhale models --provider "$provider"
    ;;

  search)
    keyword="${2:-}"
    if [ -z "$keyword" ]; then
      echo "Usage: $0 search <keyword>" >&2
      exit 1
    fi
    echo "=== Searching for '$keyword' in authenticated providers ==="
    for p in $(get_authenticated_providers); do
      matches="$(codewhale models --provider "$p" 2>/dev/null | grep -i "$keyword" || true)"
      if [ -n "$matches" ]; then
        echo ""
        echo "[$p]"
        # shellcheck disable=SC2001
        echo "$matches" | sed 's/^/  /'
      fi
    done
    ;;

  *)
    echo "Unknown subcommand: $cmd" >&2
    echo "Usage: $0 [summary | resolve | models <provider> | search <keyword>]" >&2
    exit 1
    ;;
esac
