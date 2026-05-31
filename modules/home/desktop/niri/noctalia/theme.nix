{ config, pkgs, ... }:

{
  # Generate Matugen templates as separate files for Noctalia Shell to source
  xdg.configFile."noctalia/templates/colors.css.template".text = ''
    :root {
      --noctalia-primary: {{colors.primary.dark.hex}};
      --noctalia-secondary: {{colors.secondary.dark.hex}};
      --noctalia-surface: {{colors.surface.dark.hex}};
      --noctalia-on-surface: {{colors.on_surface.dark.hex}};
      --noctalia-primary-container: {{colors.primary_container.dark.hex}};
      --noctalia-on-primary-container: {{colors.on_primary_container.dark.hex}};
    }
  '';

  xdg.configFile."noctalia/templates/discord.css.template".text = ''
    :root {
      --primary-630: {{colors.surface.dark.hex}};
      --primary-660: {{colors.surface_container.dark.hex}};
      --primary-700: {{colors.surface_container_high.dark.hex}};
      --brand-500: {{colors.primary.dark.hex}};
      --text-normal: {{colors.on_surface.dark.hex}};
    }
  '';

  xdg.configFile."noctalia/templates/neovim.lua.template".text = ''
    return {
      primary = "{{colors.primary.dark.hex}}",
      secondary = "{{colors.secondary.dark.hex}}",
      surface = "{{colors.surface.dark.hex}}",
      on_surface = "{{colors.on_surface.dark.hex}}",
      error = "{{colors.error.dark.hex}}",
    }
  '';


  xdg.configFile."noctalia/templates/ghostty.template".text = ''
    foreground = {{colors.on_surface.dark.hex}}
    background = {{colors.surface.dark.hex}}
    cursor-color = {{colors.primary.dark.hex}}
    cursor-text = {{colors.on_primary.dark.hex}}
    selection-background = {{colors.secondary_container.dark.hex}}
    selection-foreground = {{colors.on_secondary_container.dark.hex}}
  '';

  programs.noctalia-shell.settings = {
    colorSchemes = {
      darkMode = true;
      syncGsettings = true;
      useWallpaperColors = true;
      predefinedScheme = "Dracula";
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

      "neovim-colors" = {
        source = "${config.home.homeDirectory}/.config/noctalia/templates/neovim.lua.template";
        target = "${config.home.homeDirectory}/.cache/noctalia/neovim-colors.lua";
      };

      "ghostty-colors" = {
        source = "${config.home.homeDirectory}/.config/noctalia/templates/ghostty.template";
        target = "${config.home.homeDirectory}/.cache/noctalia/ghostty-colors";
      };
    };
  };
}
