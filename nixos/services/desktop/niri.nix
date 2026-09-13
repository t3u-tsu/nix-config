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

      dconf.enable = true;
    };

    # exo-open is the xdg-open backend used by niri and other helpers.
    environment.systemPackages = [ pkgs.xfce4-exo ];

    xdg.portal = {
      enable = true;
      # gnome supplies the settings daemon most apps need; its file chooser does
      # not work outside GNOME Shell, so FileChooser is routed to gtk below.
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
          "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
          "org.freedesktop.impl.portal.AppChooser" = [ "gtk" ];
        };
      };
    };

    services = {
      dbus.enable = true;
      upower.enable = true;
    };

    # Brightness/volume keys need polkit for root-free access via logind.
    security.polkit.enable = true;
  };
}
