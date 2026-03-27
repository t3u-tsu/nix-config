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
        # Color Scheme & Generation
        colorSchemes = {
          darkMode = true;
          useWallpaperColors = true;
          predefinedScheme = "Dracula";
        };

        # Integrated Dynamic Theming Templates (Matugen)
        # Ref: https://docs.noctalia.dev/theming/basic-app-theming/
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

        # UI Components - Improved layout and visibility
        bar = {
          position = "top";
          floating = false;  # Fixed to top for stability
          backgroundOpacity = 0.95;  # Increased opacity for readability
          height = 32;  # Explicit height
          margins = { top = 6; left = 12; right = 12; bottom = 0; };
          fontSize = 12;  # Explicit font size
          modules = {
            left = [ "workspaces" "window-title" ];
            center = [ "clock" ];
            right = [ "network" "cpu" "memory" "volume" "brightness" "battery" "tray" ];
          };
        };

        widgets = {
          clock = {
            format = "%Y/%m/%d (%a) %H:%M";
            fontSize = 12;
          };
          workspaces = {
            showIcons = true;
            scrollAction = "focus";
            spacing = 8;
          };
          volume = {
            showPercentage = true;
            useIcons = true;
            iconSize = 16;
          };
          brightness = {
            showPercentage = true;
            useIcons = true;
            iconSize = 16;
          };
          network = {
            showLabel = true;
            showSignal = true;
          };
          cpu = {
            showLabel = true;
            updateInterval = 1000;
          };
          memory = {
            showLabel = true;
            updateInterval = 1000;
          };
        };

        # Improved OSD (On-Screen Display)
        osd = {
          enable = true;
          position = "bottom-center";
          timeout = 2500;
          fontSize = 14;
          barHeight = 6;
          spacing = 12;
        };

        # Improved notifications
        notifications = {
          enable = true;
          position = "top-center";  # Changed from top-right for better visibility
          maxVisible = 6;
          margin = { top = 48; left = 16; right = 16; };
          fontSize = 12;
          timeout = 5000;  # Increased from 2000ms
          spacing = 10;
        };

        # Improved launcher
        launcher = {
          enable = true;
          width = 900;  # Wider for better visibility
          maxResults = 12;  # Increased from 8
          fontSize = 14;
          resultHeight = 42;  # Explicit height per result
          spacing = 8;
        };
      };
    };
  };
}
