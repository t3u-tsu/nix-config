{ config, lib, ... }:

{
  # 外部インターフェース（LAN等）でのSSHポートを閉じ、WireGuard (wg0) のみ許可する
  networking.firewall.allowedTCPPorts = lib.mkForce [];
  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 22 ];
}
