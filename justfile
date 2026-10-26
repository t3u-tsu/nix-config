# List available recipes.
default:
    @just --list

# Pass recipe arguments as "$@" so paths and agenix flags keep their boundaries.
set positional-arguments

# Rekey host secrets, passing agenix arguments through.
secret-rekey *args:
    @ysh scripts/secrets/secret.ysh rekey "$@"

# Edit a master secret file.
secret-edit file:
    @ysh scripts/secrets/secret.ysh edit "$@"

# Unlock Bitwarden (or log in) and print the session token (use: export BW_SESSION=$(just secret-unlock)).
secret-unlock *args:
    @ysh scripts/secrets/secret.ysh unlock "$@"

# Encrypt staged plaintext and rekey hosts (accepts --dry-run and --no-rekey).
secret-apply-staging *args:
    @ysh scripts/secrets/secret.ysh apply-staging "$@"

# Set user password with yescrypt and encrypt to master secrets (accepts hostnames or --all).
secret-set-host-password *args:
    @ysh scripts/secrets/set-host-password.ysh "$@"

# Restore the user SSH key from Bitwarden (hostname defaults to this host).
secret-ssh-restore *args:
    @ysh scripts/secrets/secret.ysh ssh-restore "$@"

# Back up the user SSH key to Bitwarden (hostname defaults to this host).
secret-ssh-backup *args:
    @ysh scripts/secrets/secret.ysh ssh-backup "$@"

# Check tools, master identity consistency, staging state, and Bitwarden status.
secret-doctor:
    @ysh scripts/secrets/secret.ysh doctor

# Check flake outputs without building.
check:
    nix flake check --no-build

# Run all pre-commit hooks.
lint:
    pre-commit run --all-files

# Format Nix files with nixfmt (formats all tracked Nix files when no argument is given).
fmt *files:
    @if [ "$#" -eq 0 ]; then \
        git ls-files '*.nix' | xargs nixfmt --; \
    else \
        nixfmt -- "$@"; \
    fi
