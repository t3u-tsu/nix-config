#!/usr/bin/env bash
set -euo pipefail

# Helper script for inspecting Codewhale providers and models.
# Usage:
#   ./info.sh                  # List authenticated providers & active route
#   ./info.sh models [PROVIDER]# List models for a provider
#   ./info.sh search <KEYWORD> # Search models across authenticated providers
#   ./info.sh resolve          # Show active route resolution details
#   ./info.sh update           # Refresh cached model catalogs (--update)

cmd="${1:-summary}"

get_authenticated_providers() {
  codewhale auth list | awk 'NR>1 && NF>=5 && ($5 != "missing" || $2=="yes" || $3=="yes" || $4=="yes") {print $1}'
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
    echo "  $0 update             # Refresh model catalogs (--update)"
    ;;

  resolve)
    codewhale model resolve
    ;;

  --update|update)
    [ $# -gt 0 ] && shift
    echo "=== Refreshing Codewhale Model Catalogs ==="
    codewhale models --update "$@"
    ;;

  models)
    [ $# -gt 0 ] && shift
    update_flags=()
    provider=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --update|--refresh)
          update_flags+=("--update")
          ;;
        *)
          provider="$1"
          ;;
      esac
      shift
    done
    if [ -z "$provider" ]; then
      provider="$(codewhale model resolve | awk -F': ' '$1=="provider" {print $2}')"
    fi
    echo "=== Models for provider: $provider ==="
    codewhale models "${update_flags[@]}" --provider "$provider"
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

  help|-h|--help)
    echo "Usage: $0 [summary | resolve | models [provider] [--update] | search <keyword> | update]"
    ;;

  *)
    echo "Unknown subcommand: $cmd" >&2
    echo "Usage: $0 [summary | resolve | models [provider] [--update] | search <keyword> | update]" >&2
    exit 1
    ;;
esac
