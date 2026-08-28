{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.my.services.desktop.niri;
in
{
  imports = [
    inputs.niri.nixosModules.niri
  ];

  options.my.services.desktop.niri = {
    enable = mkEnableOption "Niri scrollable-tiling Wayland compositor";
  };

  config = mkIf cfg.enable {
    programs = {
      niri = {
        enable = true;
        package = pkgs.niri;
      };

      dconf.enable = true; # Required for gsettings/dconf integration
    };

    # xfce4-exo provides `exo-open`, used as the xdg-open backend and by other
    # helper integrations.
    environment.systemPackages = [ pkgs.xfce4-exo ];

    # Necessary for screen sharing, screenshots and other desktop features
    xdg.portal = {
      enable = true;
      # Use the portals recommended for Niri
      extraPortals = with pkgs; [
        xdg-desktop-portal-gnome
        xdg-desktop-portal-gtk
      ];
      config = {
        common = {
          default = [
            "gnome"
            "gtk"
          ];
          # xdg-desktop-portal-gnome's file chooser does not work outside GNOME Shell
          "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
          "org.freedesktop.impl.portal.AppChooser" = [ "gtk" ];
        };
      };
      # xdg-desktop-portal-gnome is the primary portal for Niri
      # as it provides the settings daemon needed for many apps.
    };

    services = {
      dbus.enable = true;
      upower.enable = true;
      power-profiles-daemon.enable = true;
    };

    # Enable brightness and volume control via dbus/logind for non-root access
    security.polkit.enable = true;
  };
}
