# scripts/nebula-lib.sh — shared fleet data for the Nebula scripts.
#
# Single source of truth for the node list. Both nebula-import-secrets.sh and
# nebula-rotate-ca.sh source this file; add a new host HERE (one line), re-sign
# its cert, and re-import into SOPS — see hosts/README.md.
#
# This file is not executable; it only defines data and helper functions.
#
# shellcheck shell=bash

# Fleet: <name>|<last-octet>|<groups>
#   name   == hosts/<name>/ dir == secrets/hosts/<name>.yaml == cert basename
#   octet  == last IP octet within the 10.0.0.0/24 overlay
#   groups == Nebula groups (zone separation)
# shellcheck disable=SC2034 # consumed by the source-ing scripts
FLEET=(
  "torii-chan|1|mgmt"
  "sando-kun|2|mgmt"
  "kagutsuchi-sama|3|mgmt"
  "shosoin-tan|4|mgmt,app"
  "BrokenPC|100|mgmt,app"
  "x1c7|101|mgmt,app"
)

# SOPS secret prefix for a host (my.hostKey): lowercase, hyphens -> underscores.
# e.g. shosoin-tan -> shosoin_tan, BrokenPC -> brokenpc
host_key() {
  printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]' | tr '-' '_'
}

# Path of the per-host secrets file.
host_secrets_file() {
  printf 'secrets/hosts/%s.yaml\n' "$1"
}