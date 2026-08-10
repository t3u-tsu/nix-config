# flake/lib.nix - Shared flake-level helpers
{
  config,
  inputs,
  lib,
  ...
}:
{
  # System builder glue (inputs + overlays -> lib/default.nix), shared by
  # hosts.nix and packages.nix.
  flake.lib.mkLib = import ../lib {
    inherit (inputs)
      nixpkgs
      home-manager
      sops-nix
      nix-minecraft
      ;
    inherit inputs;
    overlays = lib.attrValues (config.flake.overlays or { });
  };
}
