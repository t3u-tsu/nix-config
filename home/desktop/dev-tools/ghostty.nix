{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.dev-tools;
in
{
  options.my.home.desktop.dev-tools.ghostty = {
    enable = mkEnableOption "Ghostty terminal emulator";
  };

  config = mkIf cfg.ghostty.enable {
    programs.ghostty = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        # Font settings
        font-family = "JetBrainsMono Nerd Font";
        font-size = 12;

        # Window settings
        background-opacity = 0.95;
        window-padding-x = 0;
        window-padding-y = 0;
        window-decoration = false;

        # Dynamic color synchronization with Noctalia (Matugen)
        config-file = "?${config.home.homeDirectory}/.cache/noctalia/ghostty-colors";
      };
    };
    home.file.".terminfo/x/xterm-ghostty".source =
      "${pkgs.ghostty.terminfo}/share/terminfo/x/xterm-ghostty";
  };
}
