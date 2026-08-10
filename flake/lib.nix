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
      nix-minecraft
      ;
    inherit inputs;
    overlays = lib.attrValues (config.flake.overlays or { });
  };
}
