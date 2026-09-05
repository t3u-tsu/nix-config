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
    enable = mkEnableOption "System-wide Dark Theme and Desktop Appearance";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      bibata-cursors
      papirus-icon-theme
      gnome-themes-extra
      adwaita-qt
      adwaita-qt6
    ];

    # GTK theme: Adwaita-dark (default dark). Noctalia gtk templates do not apply on this setup.
    gtk = {
      enable = true;
      theme = {
        name = "Adwaita-dark";
        package = pkgs.gnome-themes-extra;
      };
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      cursorTheme = {
        name = "Bibata-Modern-Amber";
        package = pkgs.bibata-cursors;
        size = 24;
      };
      gtk3.extraConfig = {
        gtk-recent-files-enabled = 0;
        gtk-recent-files-limit = 0;
        gtk-recent-files-max-age = 0;
      };
      gtk4.extraConfig = {
        gtk-recent-files-enabled = 0;
        gtk-recent-files-limit = 0;
        gtk-recent-files-max-age = 0;
      };
    };

    # Disable recent files in GNOME/GTK GSettings
    dconf.settings = {
      "org/gnome/desktop/privacy" = {
        remember-recent-files = false;
        recent-files-max-age = 0;
      };
      # Remove all CSD window buttons (minimize/maximize/close);
      # rely on keyboard shortcuts (Niri: Mod+Q close, Mod+M maximize, etc.)
      "org/gnome/desktop/wm/preferences" = {
        button-layout = ":";
      };
    };

    # Qt: force the adwaita-dark style so Qt apps (VLC etc.) stay dark.
    # (platformTheme gtk3 did not apply on this setup, so dark is driven via style.)
    qt = {
      enable = true;
      style = {
        name = "adwaita-dark";
        package = pkgs.adwaita-qt6;
      };
    };

    # Cursor Theme (Bibata Modern Amber)
    home = {
      pointerCursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Amber";
        size = 24;
        gtk.enable = true;
        x11.enable = true;
      };

      sessionVariables = {
        XCURSOR_THEME = "Bibata-Modern-Amber";
        XCURSOR_SIZE = "24";
        # Force apps to use Wayland
        MOZ_ENABLE_WAYLAND = "1";
        QT_QPA_PLATFORM = "wayland";
        NIXOS_OZONE_WL = "1";
      };
    };
  };
}
