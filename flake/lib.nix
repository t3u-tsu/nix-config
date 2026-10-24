{
  config,
  inputs,
  lib,
  ...
}:
{
  flake.lib.mkLib = import ../lib {
    inherit (inputs)
      nixpkgs
      home-manager
      sops-nix
      agenix
      agenix-rekey
      ;
    inherit inputs;
    overlays = lib.attrValues (config.flake.overlays or { });
  };
}
