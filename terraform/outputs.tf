output "torii_chan_instance_id" {
  description = "torii-chan instance ID (for the ISO injection script)"
  value       = conohavps_instance.torii_chan.id
}

output "torii_chan_addresses" {
  description = "IP address assigned to torii-chan (used to finalize wanIp)"
  value       = conohavps_instance.torii_chan.addresses
}
