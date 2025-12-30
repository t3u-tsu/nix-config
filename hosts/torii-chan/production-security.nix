{ config, lib, ... }:

{
  # Production Security Hardening
  
  # 1. SSH Access Control
  # By default (in configuration.nix), port 22 is open on all interfaces.
  # For production, we strictly limit SSH access to the WireGuard VPN interface.
  
  # Close all ports on global interfaces except for explicitly allowed ones
  networking.firewall.allowedTCPPorts = lib.mkForce [ 25565 ];

  # Open port 22 ONLY on WireGuard interface (wg0)
  # WARNING: You must have a working WireGuard peer connection to SSH into the box after deploying this!
  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 22 ];
}
