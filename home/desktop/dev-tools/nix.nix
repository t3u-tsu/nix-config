{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.dev-tools.nix;
in
{
  options.my.home.desktop.dev-tools.nix = {
    enable = mkEnableOption "Nix ecosystem development tools";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      devenv
      nh
      nix-du
      nix-index
      nix-output-monitor
      nix-tree
      nixfmt
      statix
    ];
  };
}
