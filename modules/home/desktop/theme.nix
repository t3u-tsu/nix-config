{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.theme;
in
{
  options.my.home.desktop.theme = {
    enable = mkEnableOption "System-wide Dracula Theme and Desktop Appearance";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      dracula-theme
      dracula-icon-theme
      dracula-qt5-theme
      libsForQt5.qtstyleplugin-kvantum
      kdePackages.qtstyleplugin-kvantum
    ];

    # GTK Appearance (Dracula)
    gtk = {
      enable = true;
      theme = {
        name = "Dracula";
        package = pkgs.dracula-theme;
      };
      iconTheme = {
        name = "Dracula";
        package = pkgs.dracula-icon-theme;
      };
      cursorTheme = {
        name = "Dracula-cursors";
        package = pkgs.dracula-theme;
        size = 24;
      };
    };

    # Qt Appearance Integration via Kvantum (Superior for Dracula/Noctalia)
    qt = {
      enable = true;
      platformTheme.name = "kvantum";
      style.name = "kvantum";
    };

    # Cursor Theme (Dracula)
    home.pointerCursor = {
      package = pkgs.dracula-theme;
      name = "Dracula-cursors";
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };

    home.sessionVariables = {
      XCURSOR_THEME = "Dracula-cursors";
      XCURSOR_SIZE = "24";
      # Force apps to use Wayland
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORM = "wayland";
      NIXOS_OZONE_WL = "1";
    };
  };
}
