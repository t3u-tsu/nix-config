set positional-arguments
set working-directory := '..'

[private]
default:
    @just --list update

# Update all or specified flake inputs.
flake *inputs:
    nix flake update "$@"

# Update nvfetcher managed package sources.
nvfetcher *pkgs:
    nvfetcher -c nvfetcher.toml -o _sources "$@"

# Backward-compatibility alias for nvfetcher.
[private]
sources *pkgs:
    @just update nvfetcher "$@"
