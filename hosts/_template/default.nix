{
  ...
}:

{
  imports = [
    ./hardware.nix
    ./services
    # Optional: nixos-hardware profile for the exact model, e.g.
    #   inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  # The hostname selects hosts/<name>/default.nix and the agenix rekey directory
  # secrets/rekeyed/hosts/<hostname>/, so keep them in sync.
  # Host SSH public key (/etc/ssh/ssh_host_ed25519_key.pub)
  # age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5...";
  networking.hostName = "HOSTNAME";

  # Host-specific overrides. Evaluation order is profile -> hosts/<name> ->
  # extraModules (later wins, see AGENTS.md), so mkForce/mkDefault work here.
  my = {
    # Enable role-specific functionality, e.g.
    #   services.minecraft.enable = true;
  };
}
