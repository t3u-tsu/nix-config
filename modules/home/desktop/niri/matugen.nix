{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.my.home.desktop.niri;
in {
  config = mkIf cfg.enable {
    # Matugen: Dynamic theming infrastructure
    # Note: Requires wallpaper to be set in ~/.config/niri/wallpaper
    home.packages = with pkgs; [ matugen ];

    # Template definitions for Matugen (CSS generation for Noctalia/Vesktop)
    xdg.configFile."matugen/templates/noctalia-colors.css.template".text = ''
      :root {
        --noctalia-primary: {{colors.primary.default.hex}};
        --noctalia-secondary: {{colors.secondary.default.hex}};
        --noctalia-surface: {{colors.surface.default.hex}};
        --noctalia-on-surface: {{colors.on_surface.default.hex}};
        --noctalia-primary-container: {{colors.primary_container.default.hex}};
        --noctalia-on-primary-container: {{colors.on_primary_container.default.hex}};
      }
    '';

    xdg.configFile."matugen/templates/discord-theme.css.template".text = ''
      :root {
        --primary-630: {{colors.surface.default.hex}};
        --primary-660: {{colors.surface_container.default.hex}};
        --primary-700: {{colors.surface_container_high.default.hex}};
        --brand-500: {{colors.primary.default.hex}};
        --text-normal: {{colors.on_surface.default.hex}};
      }
    '';

    # Matugen can be run manually with: matugen image ~/.config/niri/wallpaper
    # Output directories
    home.file.".config/matugen/templates/.keep".text = "";
    home.file.".cache/noctalia-generated/.keep".text = "";
  };
}
