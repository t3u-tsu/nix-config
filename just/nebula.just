set positional-arguments
set working-directory := '..'

[private]
default:
    @just --list nebula

# Rotate the Nebula mesh CA and re-sign all node certificates.
rotate-ca *args:
    @ysh scripts/nebula/rotate-ca.ysh "$@"

# Import and encrypt Nebula CA and node certificates into secrets/master.
import-secrets *args:
    @ysh scripts/nebula/import-secrets.ysh "$@"
