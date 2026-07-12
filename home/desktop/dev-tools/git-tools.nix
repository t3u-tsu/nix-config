{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.dev-tools.git-tools;
in
{
  options.my.home.desktop.dev-tools.git-tools = {
    enable = mkEnableOption "Modern Git and GitHub CLI tools";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      lazygit
      gh # GitHub CLI
    ];
  };
}
