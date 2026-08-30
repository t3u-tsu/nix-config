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
    ../../nixos
    # Optional: nixos-hardware profile for the exact model, e.g.
    #   inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  # The SOPS host key prefix (my.hostKey) is derived automatically from the
  # hostname (hyphens -> underscores), so no per-host key setup is needed here.
  networking.hostName = "HOSTNAME";

  # Host-specific overrides. Evaluation order: profile -> hosts/<name>/default.nix
  # -> extraModules (later wins, see AGENTS.md), so this file can override profile
  # defaults with mkForce / mkDefault / mkOrder when needed.
  my = {
    # Enable role-specific functionality, e.g.
    #   services.minecraft.enable = true;
  };
}
