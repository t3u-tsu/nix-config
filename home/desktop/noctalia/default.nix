{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.noctalia;
in
{
  options.my.home.desktop.noctalia = {
    enable = mkEnableOption "Noctalia Wayland shell (bar, launcher, notifications, wallpaper)";
  };

  config = mkIf cfg.enable {
    programs.noctalia = {
      enable = true;
      systemd.enable = true;

      settings = {
        shell = {
          # Launch launcher/dock/taskbar apps as transient systemd services.
          launch_apps_as_systemd_services = true;
          # Keep the live selection alive after its source app closes.
          clipboard_keep_from_closed_apps = true;
          clipboard_history_max_entries = 100;
          clipboard_confirm_clear_history = true;
          clipboard_auto_paste = "auto";
          ui_scale = 1.0;
          corner_radius_scale = 1.0;
          settings_show_advanced = true;
        };

        theme = {
          mode = "dark";
          source = "builtin";
          builtin = "Dracula";
          pure_black_dark = false;
        };

        wallpaper = {
          enabled = true;
          # Wallpapers live outside the repo; user drops images here.
          directory = "~/Pictures/wallpapers";
          fill_mode = "crop";
          transition = [ "fade" ];
          transition_duration = 1500;
          edge_smoothness = 0.3;

          default = {
            path = "~/Pictures/wallpapers/dracula-dark.png";
          };

          # Wallpaper+theme presets, switchable from the Noctalia wallpaper
          # picker's Favorites. Paths are placeholders: rename to the actual
          # files you drop into ~/Pictures/wallpapers.
          favorite = [
            {
              path = "~/Pictures/wallpapers/dracula-dark.png";
              theme_mode = "dark";
              palette_source = "builtin";
              builtin_palette = "Dracula";
            }
            {
              path = "~/Pictures/wallpapers/catppuccin.png";
              theme_mode = "dark";
              palette_source = "builtin";
              builtin_palette = "Catppuccin";
            }
            {
              path = "~/Pictures/wallpapers/tokyo-night.png";
              theme_mode = "dark";
              palette_source = "builtin";
              builtin_palette = "Tokyo-Night";
            }
          ];
        };

        backdrop = {
          enabled = true;
          blur_intensity = 0.5;
          tint_intensity = 0.3;
        };
      };
    };
  };
}
