# Platform-neutral orchestrator for the shared torii-chan role
# (nixos/services/gateway). Runs on the Orange Pi Zero3 SBC (./sbc.nix) or on a
# failover VPS (./vps.nix), never both at once; the two share hostname and
# secrets, so peers always reach torii-chan.t3u.uk without reconfiguration.
_:

{
  # Platform wiring (boot loader, WAN network) comes from the module imported
  # per-host in flake/hosts.nix (sbc.nix / vps.nix). The role itself is enabled
  # by the gateway profile.

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIODzxyWE9uLqb2HNTmzvVUgo0s4GCMewp/XjloXXU469";

  # The failover VPS must expose the same emergency tunnel as the SBC.
  my.services.emergencySsh.enable = true;
}
