{ config, lib, ... }:

with lib;

{
  imports = [
    ../../services/desktop
  ];

  config = {
    # Integrate Home-manager desktop settings for the primary user
    home-manager.users.${config.my.user.name} = { config, pkgs, ... }: {
      imports = [
        ../../home/desktop
        ../../home/desktop/niri
      ];

      my.home.desktop = {
        browsers.enable = true;
        communication.enable = true;
        dev-tools.enable = true;
        gaming.enable = true;
        gpg-signing.enable = true;
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
