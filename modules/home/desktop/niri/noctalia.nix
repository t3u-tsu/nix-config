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

        # UI Components
        bar = {
          position = "top";
          floating = true;
          backgroundOpacity = 0.8;
          margins = { top = 8; left = 8; right = 8; };
          modules = {
            left = [ "workspaces" "window-title" ];
            center = [ "clock" ];
            right = [ "network" "cpu" "memory" "volume" "brightness" "battery" "tray" ];
          };
        };

        widgets = {
          clock.format = "%Y/%m/%d (%a) %H:%M";
          workspaces = { showIcons = true; scrollAction = "focus"; };
          volume = { showPercentage = true; useIcons = true; };
          brightness = { showPercentage = true; useIcons = true; };
        };

        osd = { enable = true; position = "bottom-center"; timeout = 2000; };
        notifications = { enable = true; position = "top-right"; maxVisible = 5; margin = { top = 48; right = 16; }; };
        launcher = { enable = true; width = 600; maxResults = 8; };
      };
    };
  };
}
