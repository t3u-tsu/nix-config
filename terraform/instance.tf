# ブートボリューム（30GB）。
# 注: NixOS は後から rescue ISO（scripts/nixos-iso.sh）で上書きインストールするため、
#     ここでは一時的に ConoHa 標準 OS（Debian 12）を展開し SSH 経路を確保する。
resource "conohavps_volume" "boot" {
  name        = "${var.instance_name}-boot"
  description = "torii-chan VPS boot volume (OS replaced with NixOS via rescue ISO)"
  size        = var.boot_volume_size
  image_ref   = var.boot_image_id
  volume_type = "c3j1-ds02-boot"
}

# VPS インスタンス（512MB プラン: g2l-t-c1m512）。
# キーペアとセキュリティグループは同じ tf ファイル内で作成したものを参照する。
resource "conohavps_instance" "torii_chan" {
  instance_name_tag = var.instance_name
  admin_pass        = var.admin_password
  flavor_id         = var.flavor_id
  block_device = [
    {
      uuid = conohavps_volume.boot.id
    }
  ]
  security_group = [
    {
      name = conohavps_securitygroup.torii_chan.name
    },
  ]
  key_name    = conohavps_keypair.t3u.name
  power_state = "ACTIVE"
}
