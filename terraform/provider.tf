provider "conohavps" {
  # Explicit attributes win over CONOHAVPS_REGION, which scripts/nixos-iso.ysh does read.
  region = "c3j1"
}
