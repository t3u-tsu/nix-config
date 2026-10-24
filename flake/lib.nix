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
      agenix
      agenix-rekey
      ;
    inherit inputs;
    overlays = lib.attrValues (config.flake.overlays or { });
  };
}
