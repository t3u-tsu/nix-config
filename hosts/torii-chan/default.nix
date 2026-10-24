# Platform-neutral orchestrator for the shared torii-chan role
# (nixos/services/gateway). Runs on the Orange Pi Zero3 SBC (./sbc.nix) or on a
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
  # Platform wiring (boot loader, WAN network) comes from the module imported
  # per-host in flake/hosts.nix (sbc.nix / vps.nix). The role itself is enabled
  # by the gateway profile.

  age.rekey.hostPubkey = "age1wleksdz5clzup08vtfdwhpcy35nwsxvnnt2m5w8ktmkpzq6ctd9sael64k";

  # The failover VPS must expose the same emergency tunnel as the SBC.
  my.services.emergencySsh.enable = true;
}
