{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.my.home.desktop.niri;
in {
  config = mkIf cfg.enable {
    # Matugen: Automatic dynamic theming from wallpaper
    # Since Home Manager doesn't have programs.matugen, we manage it manually
    home.packages = with pkgs; [ matugen ];

    # Matugen configuration file
    xdg.configFile."matugen/config.toml".text = ''
      [watch]
      enable = true
      mode = "debounce"
      debounce_ms = 500

      [image]
      path = "${config.home.homeDirectory}/.config/niri/wallpaper"

      [colors]
      mode = "auto"
      scheme_kind = "dark"
    '';

    # Template definitions for Matugen
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

    # Systemd service to run Matugen on Niri startup
    systemd.user.services.matugen-watch = {
      Unit = {
        Description = "Matugen dynamic theming watcher";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.matugen}/bin/matugen image '${config.home.homeDirectory}/.config/niri/wallpaper' -c '${config.home.homeDirectory}/.config/matugen/config.toml'";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    # Create template and output directories
    home.file.".config/matugen/templates/.keep".text = "";
    home.file.".cache/noctalia-generated/.keep".text = "";
  };
}
