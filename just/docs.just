set positional-arguments
set working-directory := '..'

[private]
default:
    @just --list docs

# Lint markdown prose and validate relative links and heading anchors.
check:
    @perl scripts/docs/check-docs.pl

# Scan markdown files and convert raw in-text file paths into relative links (accepts --check).
linkify *args:
    @perl scripts/docs/linkify-markdown.pl "$@"
