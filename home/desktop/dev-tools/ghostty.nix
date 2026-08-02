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
        font-family = [
          "JetBrainsMono Nerd Font"
          "Noto Sans CJK JP"
          "Noto Color Emoji"
        ];
        font-size = 12;

        # Window settings
        background-opacity = 0.95;
        window-padding-x = 3;
        window-padding-y = 3;
        window-decoration = false;

        # Dynamic color synchronization with Noctalia (Matugen)
        config-file = "?${config.home.homeDirectory}/.cache/noctalia/ghostty-colors";
      };
    };
    home.file.".terminfo/x/xterm-ghostty".source =
      "${pkgs.ghostty.terminfo}/share/terminfo/x/xterm-ghostty";
  };
}
