set positional-arguments
set working-directory := '..'

[private]
default:
    @just --list secret

# Rekey host secrets, passing agenix arguments through.
rekey *args:
    @ysh scripts/secrets/secret.ysh rekey "$@"

# Edit a master secret file.
edit file:
    @ysh scripts/secrets/secret.ysh edit "$@"

# Unlock Bitwarden (or log in) and hand the session to the in-memory agent.
unlock *args:
    @ysh scripts/secrets/secret.ysh unlock "$@"

# Lock Bitwarden and purge the in-memory session agent.
lock:
    @ysh scripts/secrets/secret.ysh lock

# Encrypt staged plaintext and rekey hosts (accepts --dry-run and --no-rekey).
apply-staging *args:
    @ysh scripts/secrets/secret.ysh apply-staging "$@"

# Set user password with yescrypt and encrypt to master secrets (accepts hostnames or --all).
set-host-password *args:
    @ysh scripts/secrets/set-host-password.ysh "$@"

# Restore the user SSH key from Bitwarden (hostname defaults to this host).
ssh-restore *args:
    @ysh scripts/secrets/secret.ysh ssh-restore "$@"

# Back up the user SSH key to Bitwarden (hostname defaults to this host).
ssh-backup *args:
    @ysh scripts/secrets/secret.ysh ssh-backup "$@"

# Check tools, master identity consistency, staging state, and Bitwarden status.
doctor:
    @ysh scripts/secrets/secret.ysh doctor
