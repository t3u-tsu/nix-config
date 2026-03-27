{ config, pkgs, ... }:

{
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

  programs.noctalia-shell.settings = {
    colorSchemes = {
      darkMode = true;
      useWallpaperColors = true;
      predefinedScheme = "Dracula";
      matugenSchemeType = "scheme-fruit-salad";
    };

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
  };
}
