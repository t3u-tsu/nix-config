{ config, lib, ... }:

{
  # Production Security Hardening

  # 1. SSH Access Control
  # By default (in configuration.nix), port 22 is open on all interfaces.
  # For production, we strictly limit SSH access to the WireGuard VPN interface.

  # Close all ports on global interfaces except for explicitly allowed ones
  # We use mkForce to ensure only these ports are open on end0 (WAN)

  networking.firewall = {
    # interface of minecraft proxy (velocity)
    allowedTCPPorts = lib.mkForce [ 25565 ];

    interfaces.wg0.allowedTCPPorts = [ 22 ];

    interfaces.wg1 = {
      # Allow all application traffic on wg1
      allowedTCPPortRanges = [
        {
          from = 0;
          to = 65535;
        }
      ];
      allowedUDPPortRanges = [
        {
          from = 0;
          to = 65535;
        }
      ];
    };
  };
}
