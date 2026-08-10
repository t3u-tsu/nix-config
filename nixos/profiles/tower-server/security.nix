{ lib, ... }:

{
  # Disable SSH on all public/LAN interfaces and only allow it via the Nebula
  # mesh (nebula0). In-tunnel SSH (22, mgmt group) is governed by the Nebula
  # firewall (each host's nebula extraInbound).
  networking.firewall.allowedTCPPorts = lib.mkForce [ ];
}
