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

    # Use gh as the git credential helper.
    # Kept together with the gh package here (not in the desktop profile)
    # so the helper follows wherever gh is enabled. gh does not
    # cross-compile for aarch64, so SBCs/servers never pull it in.
    programs.git.settings.credential.helper = "${pkgs.gh}/bin/gh auth git-credential";
  };
}
