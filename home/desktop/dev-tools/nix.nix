{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.home.desktop.dev-tools.nix;
in
{
  options.my.home.desktop.dev-tools.nix = {
    enable = lib.mkEnableOption "Nix ecosystem development tools";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.nh
      pkgs.nix-du
      pkgs.nix-output-monitor
      pkgs.nix-tree
      pkgs.nixfmt
      pkgs.statix
    ];
  };
}
