{ lib, ... }:

{
  # Disable SSH on all public/LAN interfaces and only allow it via WireGuard (wg0)
  networking.firewall.allowedTCPPorts = lib.mkForce [ ];
  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 22 ];
}
