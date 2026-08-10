# Instance ID used as an argument to the ISO injection script (scripts/nixos-iso.sh).
output "torii_chan_instance_id" {
  description = "torii-chan instance ID (for the ISO injection script)"
  value       = conohavps_instance.torii_chan.id
}

# Assigned IP address. Used when finalizing vps.nix's wanIp / wanGateway.
# Check right after apply with "terraform output -json torii_chan_addresses".
output "torii_chan_addresses" {
  description = "IP address assigned to torii-chan (used to finalize wanIp)"
  value       = conohavps_instance.torii_chan.addresses
}
