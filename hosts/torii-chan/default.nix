# Platform-neutral orchestrator for the shared torii-chan role
# (nixos/profiles/gateway). Runs on the Orange Pi Zero3 SBC (./sbc.nix) or on a
# failover VPS (./vps.nix), never both at once; the two share hostname and
# secrets, so peers always reach torii-chan.t3u.uk without reconfiguration.
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
  ];

  # Platform wiring (boot loader, WAN network) comes from the module imported
  # per-host in flake/hosts.nix (sbc.nix / vps.nix). The role itself is enabled
  # by the gateway profile.
}
