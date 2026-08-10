# Security group for the torii-chan VPS.
#
# Open policy:
#   - 22/tcp   : SSH access for initial boot and troubleshooting. After NixOS is
#                applied, access is expected to be restricted to nebula0 only via
#                the gateway firewall (restrictAccess)
#   - 4242/udp : Nebula Lighthouse / Relay inbound (torii-chan = Lighthouse + Relay)
#   - icmp     : reachability check
#   - egress   : allow all (ConoHa SG rejects egress unless explicitly allowed)
resource "conohavps_securitygroup" "torii_chan" {
  name        = "torii-chan"
  description = "torii-chan VPS: SSH (bootstrap) + Nebula + ICMP"
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

resource "conohavps_securitygroup_rule" "nebula_lighthouse_udp" {
  securitygroup_id = conohavps_securitygroup.torii_chan.id
  direction        = "ingress"
  ethertype        = "IPv4"
  protocol         = "udp"
  port_range_min   = 4242
  port_range_max   = 4242
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
