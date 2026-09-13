{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.theme;
  palette = import ./palette.nix;

  # qt6ct color-scheme format. QPalette role order: Window, WindowText, Base,
  # AlternateBase, ToolTipBase, ToolTipText, Text, PlaceholderText, Button,
  # ButtonText, BrightText, Link, Highlight, HighlightedText, LinkVisited,
  # Light, Midlight, Dark, Mid, Shadow, Accent.
  hex = s: "#ff" + (removePrefix "#" s); # opaque Qt color
  hexA = s: "#80" + (removePrefix "#" s); # translucent Qt color (Accent)

  active =
    with palette;
    "${hex bg}, #ffffffff, ${hex bg}, ${hex bg2}, ${hex bg2}, #ffffffff, #ffffffff, ${hex fg2}, ${hex bg2}, #ffffffff, #ffffffff, ${hex secondary}, ${hex primary}, #ff000000, ${hex link}, ${hex low}, ${hex bg2}, ${hex bg}, ${hex bg2}, #ff000000, ${hexA primary}";
  disabled =
    with palette;
    "${hex low}, ${hex fg2}, ${hex low}, ${hex bg2}, ${hex bg2}, ${hex fg2}, ${hex fg2}, ${hex low}, ${hex low}, ${hex fg2}, ${hex fg2}, ${hex secondary}, ${hex primary}, #ff000000, ${hex link}, ${hex low}, ${hex bg2}, ${hex bg}, ${hex bg2}, #ff000000, ${hexA primary}";

  qtVesperScheme = ''
    [ColorScheme]
    active_colors=${active}
    disabled_colors=${disabled}
    inactive_colors=${active}
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
      rose-pine-gtk-theme
      qt6Packages.qt6ct
      # Dependencies of the Noctalia libreoffice template (its apply.sh uses
      # python3 + zip to build the .oxt).
      python3
      zip
    ];

    # GTK theme: Rosé Pine dark (Vesper-friendly low-contrast palette;
    # Noctalia gtk templates do not apply on this setup).
    gtk = {
      enable = true;
      theme = {
        name = "rose-pine";
        package = pkgs.rose-pine-gtk-theme;
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
            color_scheme_path=${config.home.homeDirectory}/.config/qt6ct/colors/vesper.conf
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
