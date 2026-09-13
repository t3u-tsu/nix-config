# shellcheck shell=bash
# Single source of truth for the node list: add a new host here, sign its cert,
# then re-import it into SOPS (see hosts/README.md).

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

# Must match the SOPS key prefix used elsewhere (my.hostKey).
host_key() {
  printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]' | tr '-' '_'
}

host_secrets_file() {
  printf 'secrets/hosts/%s.yaml\n' "$1"
}