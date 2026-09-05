{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.theme;

  # Vesper-flavoured Qt6 palette, in qt6ct color-scheme format (QPalette role
  # order: Window, WindowText, Base, AlternateBase, ToolTipBase, ToolTipText,
  # Text, PlaceholderText, Button, ButtonText, BrightText, Link, Highlight,
  # HighlightedText, LinkVisited, Light, Midlight, Dark, Mid, Shadow, Accent).
  # Surface #0c0c0c, surfaceVariant #1c1c1c, primary #FFC799, secondary #99FFE4.
  qtVesperScheme = ''
    [ColorScheme]
    active_colors=#ff0c0c0c, #ffffffff, #ff0c0c0c, #ff1c1c1c, #ff1c1c1c, #ffffffff, #ffffffff, #ffa0a0a0, #ff1c1c1c, #ffffffff, #ffffffff, #ff99ffe4, #ffffc799, #ff000000, #ff80b3ff, #ff505050, #ff1c1c1c, #ff0c0c0c, #ff1c1c1c, #ff000000, #80ffc799
    disabled_colors=#ff505050, #ffa0a0a0, #ff505050, #ff1c1c1c, #ff1c1c1c, #ffa0a0a0, #ffa0a0a0, #ff505050, #ff505050, #ffa0a0a0, #ffa0a0a0, #ff99ffe4, #ffffc799, #ff000000, #ff80b3ff, #ff505050, #ff1c1c1c, #ff0c0c0c, #ff1c1c1c, #ff000000, #80ffc799
    inactive_colors=#ff0c0c0c, #ffffffff, #ff0c0c0c, #ff1c1c1c, #ff1c1c1c, #ffffffff, #ffffffff, #ffa0a0a0, #ff1c1c1c, #ffffffff, #ffffffff, #ff99ffe4, #ffffc799, #ff000000, #ff80b3ff, #ff505050, #ff1c1c1c, #ff0c0c0c, #ff1c1c1c, #ff000000, #80ffc799
  '';
in
{
  options.my.home.desktop.theme = {
    enable = mkEnableOption "System-wide Dark Theme and Desktop Appearance";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      bibata-cursors
      papirus-icon-theme
      orchis-theme
      qt6Packages.qt6ct
      # Dependencies of the Noctalia libreoffice template (its apply.sh uses
      # python3 + zip to build the .oxt).
      python3
      zip
    ];

    # GTK theme: Orchis Orange Dark (dark fallback; Noctalia gtk templates do
    # not apply on this setup).
    gtk = {
      enable = true;
      theme = {
        name = "Orchis-Orange-Dark";
        package = pkgs.orchis-theme;
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

    # Qt driven by qt6ct: QT_QPA_PLATFORMTHEME=qt6ct + a Vesper color scheme.
    qt = {
      enable = true;
      platformTheme = {
        name = "qt6ct";
      };
    };

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

      file = {
        # Point qt6ct at the Vesper color scheme. home.file keys are relative
        # to $HOME, so .config/ lands these under ~/.config.
        ".config/qt6ct/qt6ct.conf" = {
          text = ''
            [Appearance]
            custom_palette=false
            style=Fusion
            color_scheme_path=/home/t3u/.config/qt6ct/colors/vesper.conf
            standard_dialogs=default
          '';
        };
        ".config/qt6ct/colors/vesper.conf" = {
          text = qtVesperScheme;
        };
        # Pre-create ~/.config/heroic so the Noctalia heroiclauncher template
        # can place matugen.css there (its requires_path check needs the dir).
        ".config/heroic/themes/.keep" = {
          text = "";
        };
      };
    };
  };
}
