# Host: torii-chan (WireGuard gateway / VPN server + DDNS + Minecraft forward)
#
# This is the PLATFORM-NEUTRAL orchestrator for the shared "torii-chan" role.
# The role itself lives in nixos/profiles/gateway and can run on either:
#   - the physical Orange Pi Zero3 SBC  (platform layer: ./sbc.nix)
#   - a failover VPS                    (platform layer: ./vps.nix)
# Only ONE runs at a time (failover). Both share hostname `torii-chan` and the
# SAME secrets (WireGuard keys, DDNS token) so peers keep reaching this host at
# torii-chan.t3u.uk without reconfiguration.
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ../../nixos
    ../../nixos/profiles/gateway
  ];

  nixpkgs.overlays = [
  ];

  # The torii-chan role (WireGuard gateway + NAT/Minecraft forward + DDNS).
  # Platform-specific wiring (boot loader, WAN network) is provided by the
  # matching platform module imported per-host in flake/hosts.nix.
  my.services.gateway.enable = true;
}
