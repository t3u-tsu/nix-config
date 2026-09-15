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
    cursor = {
      name = mkOption {
        type = types.str;
        default = "Bibata-Modern-Amber";
        description = "Cursor theme, shared with the Niri compositor.";
      };
      size = mkOption {
        type = types.int;
        default = 24;
        description = "Cursor size in pixels.";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      bibata-cursors
      papirus-icon-theme
      qt6Packages.qt6ct
    ];

    # Neutral Adwaita-shaped base; Noctalia's gtk3/gtk4 templates paint the
    # Vesper colors on top via ~/.config/gtk-{3,4}.0/gtk.css.
    gtk = {
      enable = true;
      theme = {
        name = "adw-gtk3-dark";
        package = pkgs.adw-gtk3;
      };
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      cursorTheme = {
        name = cfg.cursor.name;
        package = pkgs.bibata-cursors;
        size = cfg.cursor.size;
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

    dconf.settings = {
      "org/gnome/desktop/privacy" = {
        remember-recent-files = false;
        recent-files-max-age = 0;
      };
      # ":" removes all CSD window buttons (Niri binds Mod+Q / Mod+M etc.).
      "org/gnome/desktop/wm/preferences" = {
        button-layout = ":";
      };
    };

    qt = {
      enable = true;
      platformTheme = {
        name = "qt6ct";
      };
    };

    home = {
      pointerCursor = {
        package = pkgs.bibata-cursors;
        name = cfg.cursor.name;
        size = cfg.cursor.size;
        gtk.enable = true;
        x11.enable = true;
      };

      sessionVariables = {
        XCURSOR_THEME = cfg.cursor.name;
        XCURSOR_SIZE = toString cfg.cursor.size;
        MOZ_ENABLE_WAYLAND = "1";
        QT_QPA_PLATFORM = "wayland";
        NIXOS_OZONE_WL = "1";
      };

      file = {
        # qt6ct reads the color scheme Noctalia's "qt" template keeps in
        # ~/.config/qt6ct/colors/noctalia.conf; only the selector is ours.
        ".config/qt6ct/qt6ct.conf" = {
          text = ''
            [Appearance]
            custom_palette=false
            style=Fusion
            color_scheme_path=${config.home.homeDirectory}/.config/qt6ct/colors/noctalia.conf
            standard_dialogs=default
          '';
        };
        # Noctalia's heroiclauncher template writes matugen.css here, but its
        # requires_path check needs the directory to exist first.
        ".config/heroic/themes/.keep" = {
          text = "";
        };
      };
    };
  };
}
