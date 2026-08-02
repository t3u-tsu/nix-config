# ConoHa VPS provider (gmo-internet/conohavps, ベータ版)
#
# 認証情報はハードコードせず、環境変数から読み込む:
#   CONOHAVPS_USER_ID / CONOHAVPS_PASSWORD / CONOHAVPS_TENANT_ID
#   CONOHAVPS_REGION（省略時デフォルト c3j1） / CONOHAVPS_IDENTITY_ENDPOINT
#
# 本リポジトリでは SOPS から下記のように注入して使用する（README.md 参照）:
#   export CONOHAVPS_USER_ID=$(sops -d --extract '["OPENSTACK_USER_ID"]' secrets/services/conoha-vps-mcp.yaml)
#   export CONOHAVPS_PASSWORD=$(sops -d --extract '["OPENSTACK_PASSWORD"]' secrets/services/conoha-vps-mcp.yaml)
#   export CONOHAVPS_TENANT_ID=$(sops -d --extract '["OPENSTACK_TENANT_ID"]' secrets/services/conoha-vps-mcp.yaml)
provider "conohavps" {
  region = "c3j1" # ConoHa VPS リージョン（プロバイダのデフォルトと同じだが明示）
}
