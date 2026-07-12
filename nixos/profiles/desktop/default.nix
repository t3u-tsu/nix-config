{ config, lib, ... }:

with lib;

{
  imports = [
    ../../services/desktop
  ];

  config = {
    my = {
      # Comin automatic deployment (default: enabled)
      services.deployment.comin.enable = lib.mkDefault true;

      # System-wide desktop services
      services.desktop = {
        niri.enable = true;
        greetd.enable = true;
        pipewire.enable = true;
        gaming.enable = true;
      };

      # WCH-LinkE udev rules (defined in nixos/hardware/wch-linke.nix)
      hardware.dev-tools.wch-linke.enable =
        config.home-manager.users.${config.my.user.name}.my.home.desktop.dev-tools.hardware.enable;
    };

    # Integrate Home-manager desktop settings for the primary user
    home-manager.users.${config.my.user.name} = { config, pkgs, ... }: {
      imports = [
        ../../../home/desktop
      ];

      my.home.desktop = {
        browsers.enable = true;
        communication.enable = true;
        dev-tools.enable = true;
        gaming.enable = true;
        gpg-signing.enable = true;
        media.enable = true;
        creative.enable = true;
        theme.enable = true;
        xdg.enable = true;
        locales.enable = true;
        niri.enable = true; # Force niri
      };
    };
  };
}
