{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.services.desktop.fonts;
in
{
  options.my.services.desktop.fonts = {
    enable = mkEnableOption "System fonts" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    fonts = {
      packages = with pkgs; [
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
        nerd-fonts.jetbrains-mono
      ];

      fontconfig = {
        defaultFonts = {
          serif = [
            "Noto Serif CJK JP"
            "Noto Color Emoji"
          ];
          sansSerif = [
            "Noto Sans CJK JP"
            "Noto Color Emoji"
          ];
          monospace = [
            "JetBrainsMono Nerd Font"
            "Noto Sans CJK JP"
            "Noto Color Emoji"
          ];
        };
      };
    };
  };
}
