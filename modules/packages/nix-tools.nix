{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.my.packages.nix-tools;
in
{
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      nh
      nix-du
      nix-index
      nix-output-monitor
      nix-tree
      nixfmt
    ];
  };
}
