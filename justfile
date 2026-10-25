# List available recipes.
default:
    @just --list

# Pass recipe arguments as "$@" so paths and agenix flags keep their boundaries.
set positional-arguments

# Rekey host secrets, passing agenix arguments through.
secret-rekey *args:
    ysh scripts/secret.ysh rekey "$@"

# Edit a master secret file.
secret-edit file:
    ysh scripts/secret.ysh edit "$@"

# Encrypt staged plaintext and rekey hosts (accepts --dry-run and --no-rekey).
secret-apply-staging *args:
    ysh scripts/secret.ysh apply-staging "$@"

# Check tools, master identity consistency, staging state, and Bitwarden status.
secret-doctor:
    ysh scripts/secret.ysh doctor

# Check flake outputs without building.
check:
    nix flake check --no-build

# Run all pre-commit hooks.
lint:
    pre-commit run --all-files

# Format Nix files with nixfmt.
fmt *files:
    @if [ "$#" -eq 0 ]; then echo 'usage: just fmt <file...>' >&2; exit 2; fi
    nixfmt -- "$@"
