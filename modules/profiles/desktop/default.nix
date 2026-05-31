{ config, lib, ... }:

with lib;

{
  imports = [
    ../../services/desktop
  ];

  config = {
    # Integrate Home-manager desktop settings for the primary user
    home-manager.users.${config.my.user.name} = { pkgs, ... }: {
      imports = [
        ../../home/desktop
        ../../home/desktop/niri
      ];

      # Ghostty terminfo を配置し、SSH 接続時の端末定義エラーを解消（デスクトップのみ）
      home.file.".terminfo/x/xterm-ghostty".source = "${pkgs.ghostty.terminfo}/share/terminfo/x/xterm-ghostty";

      # Enable desktop categories by default in this profile
      my.home.desktop = {
        browsers.enable = true;
        communication.enable = true;
        dev-tools.enable = true;
        gaming.enable = true;
        media.enable = true;
        utils.enable = true;
        creative.enable = true;
        theme.enable = true;
        xdg.enable = true;
        locales.enable = true;
        niri.enable = true; # Force niri
      };
    };

    # System-wide services
    my.services.desktop = {
      niri.enable = true;
      greetd.enable = true;
      pipewire.enable = true;
      gaming.enable = true;
    };
  };
}
