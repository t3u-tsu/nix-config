# List available recipes.
default:
    @just --list

# Rekey host secrets, passing agenix arguments through.
secret-rekey *args:
    ysh scripts/secret.ysh rekey {{args}}

# Edit a master secret file.
secret-edit file:
    ysh scripts/secret.ysh edit {{file}}

# Encrypt staged plaintext and rekey hosts.
secret-apply-staging:
    ysh scripts/secret.ysh apply-staging

# Check flake outputs without building.
check:
    nix flake check --no-build

# Run all pre-commit hooks.
lint:
    pre-commit run --all-files

# Format Nix files with nixfmt.
fmt *files:
    nixfmt {{files}}
