set positional-arguments
set working-directory := '..'

[private]
default:
    @just --list qa

# Check flake outputs without building.
check:
    nix flake check --no-build

# Run all pre-commit hooks across the repository.
lint:
    pre-commit run --all-files

# Format Nix files with nixfmt (formats all tracked Nix files when no argument is given).
fmt *files:
    @if [ "$#" -eq 0 ]; then \
        git ls-files '*.nix' | xargs nixfmt --; \
    else \
        nixfmt -- "$@"; \
    fi
