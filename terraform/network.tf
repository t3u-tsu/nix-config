# torii-chan VPS 用セキュリティグループ。
#
# 開放方針:
#   - 22/tcp   : 初期ブート時・障害時の SSH アクセス。NixOS 適用後は gateway の
#                firewall（restrictAccess）で wg0 経由のみに制限される想定
#   - 51820-51821/udp: WireGuard（wg0 / wg1）の受信
#   - icmp     : 疎通確認
#   - egress   : 全許可（ConoHa の SG は明示しないと egress も拒否されるため明示）
resource "conohavps_securitygroup" "torii_chan" {
  name        = "torii-chan"
  description = "torii-chan VPS: SSH (bootstrap) + WireGuard + ICMP"
}

resource "conohavps_securitygroup_rule" "ssh_ipv4" {
  securitygroup_id = conohavps_securitygroup.torii_chan.id
  direction        = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 22
  port_range_max   = 22
}

resource "conohavps_securitygroup_rule" "ssh_ipv6" {
  securitygroup_id = conohavps_securitygroup.torii_chan.id
  direction        = "ingress"
  ethertype        = "IPv6"
  protocol         = "tcp"
  port_range_min   = 22
  port_range_max   = 22
}

resource "conohavps_securitygroup_rule" "wireguard_udp" {
  securitygroup_id = conohavps_securitygroup.torii_chan.id
  direction        = "ingress"
  ethertype        = "IPv4"
  protocol         = "udp"
  port_range_min   = 51820
  port_range_max   = 51821
}

resource "conohavps_securitygroup_rule" "icmp_ipv4" {
  securitygroup_id = conohavps_securitygroup.torii_chan.id
  direction        = "ingress"
  ethertype        = "IPv4"
  protocol         = "icmp"
}

resource "conohavps_securitygroup_rule" "egress_all_ipv4" {
  securitygroup_id = conohavps_securitygroup.torii_chan.id
  direction        = "egress"
  ethertype        = "IPv4"
}
