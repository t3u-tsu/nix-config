{ config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.my.home.desktop.niri;
in {
  imports = [
    inputs.noctalia-shell.homeModules.default
  ];

  config = mkIf cfg.enable {
    # Generate Matugen templates as separate files for Noctalia Shell to source
    xdg.configFile."noctalia/templates/colors.css.template".text = ''
      :root {
        --noctalia-primary: {{colors.primary.default.hex}};
        --noctalia-secondary: {{colors.secondary.default.hex}};
        --noctalia-surface: {{colors.surface.default.hex}};
        --noctalia-on-surface: {{colors.on_surface.default.hex}};
        --noctalia-primary-container: {{colors.primary_container.default.hex}};
        --noctalia-on-primary-container: {{colors.on_primary_container.default.hex}};
      }
    '';

    xdg.configFile."noctalia/templates/discord.css.template".text = ''
      :root {
        --primary-630: {{colors.surface.default.hex}};
        --primary-660: {{colors.surface_container.default.hex}};
        --primary-700: {{colors.surface_container_high.default.hex}};
        --brand-500: {{colors.primary.default.hex}};
        --text-normal: {{colors.on_surface.default.hex}};
      }
    '';

    programs.noctalia-shell = {
      enable = true;
      systemd.enable = true;
      
      settings = {
        settingsVersion = 0;

        # Color Scheme & Generation
        colorSchemes = {
          darkMode = true;
          useWallpaperColors = true;
          predefinedScheme = "Dracula";
          matugenSchemeType = "scheme-fruit-salad";
        };

        # Integrated Dynamic Theming Templates (Matugen)
        templates = {
          "zen-colors" = {
            source = "${config.home.homeDirectory}/.config/noctalia/templates/colors.css.template";
            target = "${config.home.homeDirectory}/.cache/noctalia/colors.css";
          };
          
          "discord-theme" = {
            source = "${config.home.homeDirectory}/.config/noctalia/templates/discord.css.template";
            target = "${config.home.homeDirectory}/.config/vesktop/themes/noctalia.css";
          };
        };

        # General UI Settings
        general = {
          language = "ja";
          fontDefault = "Noto Sans CJK JP";
          fontFixed = "Noto Sans Mono CJK JP";
          radiusRatio = 1.0;
          animationSpeed = 1.0;
        };

        # UI Components - Improved layout and visibility
        bar = {
          position = "top";
          floating = false;
          backgroundOpacity = 0.95;
          height = 32;
          marginVertical = 4;
          marginHorizontal = 8;
          
          widgets = {
            left = [
              { id = "Workspace"; labelMode = "name"; showApplications = true; }
              { id = "Launcher"; icon = "noctalia"; }
            ];
            center = [
              { id = "ActiveWindow"; maxWidth = 400; }
            ];
            right = [
              { id = "Network"; displayMode = "alwaysShow"; }
              { id = "Volume"; displayMode = "alwaysShow"; middleClickCommand = "pavucontrol"; }
              { id = "Brightness"; displayMode = "onhover"; }
              { id = "Battery"; displayMode = "onhover"; }
              { id = "Clock"; formatHorizontal = "yyyy/MM/dd (EEE) HH:mm"; }
              { id = "Tray"; drawerEnabled = true; }
              { id = "NotificationHistory"; showUnreadBadge = true; }
              { id = "ControlCenter"; icon = "noctalia"; }
            ];
          };
        };

        # Improved OSD (On-Screen Display)
        osd = {
          enabled = true;
          location = "bottom_center";
          autoHideMs = 2500;
        };

        # Improved notifications
        notifications = {
          enabled = true;
          location = "top_center";
          normalUrgencyDuration = 5;
          criticalUrgencyDuration = 10;
        };

        # Launcher settings
        appLauncher = {
          position = "center";
          viewMode = "list";
          sortByMostUsed = true;
          enableClipboardHistory = true;
        };

        # Session & Power Menu
        sessionMenu = {
          position = "center";
          powerOptions = [
            { action = "lock"; enabled = true; }
            { action = "suspend"; enabled = true; }
            { action = "reboot"; enabled = true; }
            { action = "logout"; enabled = true; }
            { action = "shutdown"; enabled = true; }
          ];
        };
      };
    };
  };
}
