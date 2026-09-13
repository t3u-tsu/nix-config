provider "conohavps" {
  # Explicit attributes win over CONOHAVPS_REGION, which scripts/nixos-iso.sh does read.
  region = "c3j1"
}
