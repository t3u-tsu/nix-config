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
  # Import the niri-flake NixOS module at the top level
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

      xfconf.enable = true; # Required for Thunar settings persistence
      dconf.enable = true; # Required for gsettings/dconf integration

      thunar = {
        enable = true;
        plugins = with pkgs; [
          thunar-archive-plugin
          thunar-volman
        ];
      };
    };

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

    # Core desktop services
    services = {
      dbus.enable = true;
      upower.enable = true;
      power-profiles-daemon.enable = true;
      gvfs.enable = true; # Required for file manager features (Trash, Mounts)
      tumbler.enable = true; # Required for file manager thumbnails
    };

    # Enable brightness and volume control via dbus/logind for non-root access
    security.polkit.enable = true;
  };
}
