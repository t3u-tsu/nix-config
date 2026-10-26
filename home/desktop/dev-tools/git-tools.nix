{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.home.desktop.dev-tools.git-tools;
in
{
  options.my.home.desktop.dev-tools.git-tools = {
    enable = lib.mkEnableOption "Modern Git and GitHub CLI tools";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.lazygit
      pkgs.gh
    ];

    programs.git.settings.credential.helper = "${pkgs.gh}/bin/gh auth git-credential";
  };
}
