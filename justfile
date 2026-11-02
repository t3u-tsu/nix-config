# List available subcommands and recipes.
default:
    @just --list

set positional-arguments

# System operations (switch, test, boot, build, diff, gc).
mod system 'just/system.just'

# Secrets management via agenix and Bitwarden.
mod secret 'just/secret.just'

# Quality assurance, linting, and formatting.
mod qa 'just/qa.just'

# Documentation verification and link rewriting.
mod docs 'just/docs.just'

# Dependency and external package updates.
mod update 'just/update.just'

# Nebula mesh VPN CA and certificate operations.
mod nebula 'just/nebula.just'

# Hardware quirks and recovery helpers.
mod hardware 'just/hardware.just'

# Shortcut: Build and activate system configuration.
switch *args:
    @just system switch "$@"

# Shortcut: Build and activate system configuration temporarily without bootloader update.
test *args:
    @just system test "$@"

# Shortcut: Preview system changes without applying (dry run).
diff *args:
    @just system diff "$@"

# Shortcut: Build system configuration without activating.
build *args:
    @just system build "$@"

# Shortcut: Check flake outputs without building.
check:
    @just qa check

# Shortcut: Run all pre-commit hooks.
lint:
    @just qa lint

# Shortcut: Format Nix files.
fmt *files:
    @just qa fmt "$@"

# Legacy backward-compatibility aliases
[private]
secret-rekey *args:
    @just secret rekey "$@"

[private]
secret-edit file:
    @just secret edit "$@"

[private]
secret-unlock *args:
    @just secret unlock "$@"

[private]
secret-lock:
    @just secret lock

[private]
secret-apply-staging *args:
    @just secret apply-staging "$@"

[private]
secret-set-host-password *args:
    @just secret set-host-password "$@"

[private]
secret-ssh-restore *args:
    @just secret ssh-restore "$@"

[private]
secret-ssh-backup *args:
    @just secret ssh-backup "$@"

[private]
secret-doctor:
    @just secret doctor
