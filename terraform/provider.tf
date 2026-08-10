# ConoHa VPS provider (gmo-internet/conohavps, beta)
#
# Credentials are not hardcoded; they are read from environment variables:
#   CONOHAVPS_USER_ID / CONOHAVPS_PASSWORD / CONOHAVPS_TENANT_ID
#   CONOHAVPS_REGION (defaults to c3j1 when omitted) / CONOHAVPS_IDENTITY_ENDPOINT
#
# In this repository they are injected from SOPS as shown below (see README.md):
#   export CONOHAVPS_USER_ID=$(sops -d --extract '["OPENSTACK_USER_ID"]' secrets/services/conoha-vps-mcp.yaml)
#   export CONOHAVPS_PASSWORD=$(sops -d --extract '["OPENSTACK_PASSWORD"]' secrets/services/conoha-vps-mcp.yaml)
#   export CONOHAVPS_TENANT_ID=$(sops -d --extract '["OPENSTACK_TENANT_ID"]' secrets/services/conoha-vps-mcp.yaml)
provider "conohavps" {
  region = "c3j1" # ConoHa VPS region (same as provider default, but explicit)
}
