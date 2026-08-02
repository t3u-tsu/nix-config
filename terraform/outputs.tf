# インスタンス ID は ISO 注入スクリプト（scripts/nixos-iso.sh）の引数に使う。
output "torii_chan_instance_id" {
  description = "torii-chan インスタンス ID（ISO 注入スクリプト用）"
  value       = conohavps_instance.torii_chan.id
}

# 割り当てられた IP アドレス。vps.nix の wanIp / wanGateway を確定するときに使う。
# apply 直後に「terraform output -json torii_chan_addresses」で確認する。
output "torii_chan_addresses" {
  description = "torii-chan に割り当てられた IP アドレス（wanIp の確定に使用）"
  value       = conohavps_instance.torii_chan.addresses
}
