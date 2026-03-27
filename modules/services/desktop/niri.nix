{ pkgs, inputs, config, lib, ... }:

with lib;
let
  cfg = config.my.services.desktop.niri;
in {
  # Import the niri-flake NixOS module at the top level
  imports = [ 
    inputs.niri.nixosModules.niri 
  ];

  options.my.services.desktop.niri = {
    enable = mkEnableOption "Niri scrollable-tiling Wayland compositor";
  };

  config = mkIf cfg.enable {
    programs.niri = {
      enable = true;
      package = pkgs.niri;
    };

    # Necessary for screen sharing, screenshots and other desktop features
    xdg.portal = {
      enable = true;
      # Use the portals recommended for Niri
      extraPortals = with pkgs; [ 
        xdg-desktop-portal-gnome
        xdg-desktop-portal-gtk
      ];
      config.common.default = [ "gnome" "gtk" ];
      # xdg-desktop-portal-gnome is the primary portal for Niri
      # as it provides the settings daemon needed for many apps.
    };

    # Core desktop services
    services.dbus.enable = true;
    services.upower.enable = true;
    services.power-profiles-daemon.enable = true;
    services.gvfs.enable = true; # Required for Nautilus features
    
    # Enable brightness and volume control via dbus/logind for non-root access
    security.polkit.enable = true;
  };
}
