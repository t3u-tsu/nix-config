{ config, lib, ... }:

{
  # Production Security Hardening
  
  # 1. SSH Access Control
  # By default (in configuration.nix), port 22 is open on all interfaces.
  # For production, we strictly limit SSH access to the WireGuard VPN interface.
  
  # Close all ports on global interfaces except for explicitly allowed ones
  # We use mkForce to ensure only these ports are open on end0 (WAN)

  # interface of minecraft proxy (velocity)
  networking.firewall.allowedTCPPorts = lib.mkForce [ 25565 ];

  # Open port 22 (SSH), 8080 (update-hub), and Monitoring Dashboard (3000, 9090, 9100) ONLY on WireGuard management interface
  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 22 3000 8080 9090 9100 ];

  # Allow all application traffic on wg1
  networking.firewall.interfaces.wg1.allowedTCPPortRanges = [ { from = 0; to = 65535; } ];
  networking.firewall.interfaces.wg1.allowedUDPPortRanges = [ { from = 0; to = 65535; } ];
}
