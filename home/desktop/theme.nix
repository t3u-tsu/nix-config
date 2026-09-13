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

  # qt6ct color-scheme entries are positional and follow QPalette's color-role
  # order; reordering them by hand breaks the theme.
  opaqueHex = s: "#ff" + (removePrefix "#" s);
  translucentHex = s: "#80" + (removePrefix "#" s);

  active =
    with palette;
    "${opaqueHex bg}, #ffffffff, ${opaqueHex bg}, ${opaqueHex bg2}, ${opaqueHex bg2}, #ffffffff, #ffffffff, ${opaqueHex fg2}, ${opaqueHex bg2}, #ffffffff, #ffffffff, ${opaqueHex secondary}, ${opaqueHex primary}, #ff000000, ${opaqueHex link}, ${opaqueHex low}, ${opaqueHex bg2}, ${opaqueHex bg}, ${opaqueHex bg2}, #ff000000, ${translucentHex primary}";
  disabled =
    with palette;
    "${opaqueHex low}, ${opaqueHex fg2}, ${opaqueHex low}, ${opaqueHex bg2}, ${opaqueHex bg2}, ${opaqueHex fg2}, ${opaqueHex fg2}, ${opaqueHex low}, ${opaqueHex low}, ${opaqueHex fg2}, ${opaqueHex fg2}, ${opaqueHex secondary}, ${opaqueHex primary}, #ff000000, ${opaqueHex link}, ${opaqueHex low}, ${opaqueHex bg2}, ${opaqueHex bg}, ${opaqueHex bg2}, #ff000000, ${translucentHex primary}";

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
      rose-pine-gtk-theme
      qt6Packages.qt6ct
      # Dependencies of the Noctalia libreoffice template (its apply.sh uses
      # python3 + zip to build the .oxt).
      python3
      zip
    ];

    # Rosé Pine dark GTK theme (Vesper-friendly, low contrast); Noctalia's gtk
    # templates do not apply on this setup.
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
        # home.file keys are relative to $HOME, so this lands in ~/.config/qt6ct.
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
        # Noctalia's heroiclauncher template writes matugen.css here, but its
        # requires_path check needs the directory to exist first.
        ".config/heroic/themes/.keep" = {
          text = "";
        };
      };
    };
  };
}
