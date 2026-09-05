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
    ];

    # GTK: cursor & icons stay Dracula; GTK/Qt color now comes from
    # Noctalia app-theming templates (gtk3/gtk4/qt).
    gtk = {
      enable = true;
      iconTheme = {
        name = "Dracula";
        package = pkgs.dracula-icon-theme;
      };
      cursorTheme = {
        name = "Dracula-cursors";
        package = pkgs.dracula-theme;
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

    # Cursor Theme (Dracula)
    home = {
      pointerCursor = {
        package = pkgs.dracula-theme;
        name = "Dracula-cursors";
        size = 24;
        gtk.enable = true;
        x11.enable = true;
      };

      sessionVariables = {
        XCURSOR_THEME = "Dracula-cursors";
        XCURSOR_SIZE = "24";
        # Force apps to use Wayland
        MOZ_ENABLE_WAYLAND = "1";
        QT_QPA_PLATFORM = "wayland";
        NIXOS_OZONE_WL = "1";
      };
    };
  };
}
