{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ./hardware.nix
    ./services
    # Optional: nixos-hardware profile for the exact model, e.g.
    #   inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  # agenix-rekey: specify the host public key derived from /etc/ssh/ssh_host_ed25519_key.pub
  # via `ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub`
  # age.rekey.hostPubkey = "age1...";

  networking.hostName = "HOSTNAME";

  # Host-specific overrides. Evaluation order is profile -> hosts/<name> ->
  # extraModules (later wins, see AGENTS.md), so mkForce/mkDefault work here.
  my = {
    # Enable role-specific functionality, e.g.
    #   services.minecraft.enable = true;
  };
}
