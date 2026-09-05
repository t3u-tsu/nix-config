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
          source = "community";
          community_palette = "Vesper";
          pure_black_dark = false;

          # Sync the shell palette into other apps. Only templates verified to
          # apply on this setup are enabled; Qt/Spicetify showed issues.
          templates = {
            enable_builtin_templates = true;
            builtin_ids = [ "ghostty" ];
            enable_community_templates = true;
            community_ids = [
              "neovim"
              "discord"
              "lazygit"
              "obs"
              "prismlauncher"
              "heroiclauncher"
            ];
          };
        };

        wallpaper = {
          enabled = true;
          # Slideshow source: PTITSA set under the external Pictures dir.
          directory = "${config.home.homeDirectory}/Pictures/wallpapers/PTITSA";
          fill_mode = "crop";
          transition = [ "fade" ];
          transition_duration = 1500;
          edge_smoothness = 0.3;

          default = {
            path = "${config.home.homeDirectory}/Pictures/wallpapers/PTITSA/114631433_p0.jpg";
          };

          # Rotate through the folder on an interval (slideshow).
          automation = {
            enabled = true;
            interval_seconds = 300;
            order = "random";
            recursive = true;
          };
        };

        backdrop = {
          enabled = true;
          blur_intensity = 0.5;
          tint_intensity = 0.3;
        };
      };
    };

    # Heroic reads its custom themes from customThemesPath; when unset it does
    # not scan ~/.config/heroic/themes, so the Noctalia matugen theme stays
    # invisible. Seed it once (only while empty) so it stays user-editable.
    home.activation.heroicCustomThemesPath = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      cfg="$HOME/.config/heroic/config.json"
      if [ -f "$cfg" ] && grep -q '"customThemesPath": ""' "$cfg"; then
        sed -i 's|"customThemesPath": ""|"customThemesPath": "${config.home.homeDirectory}/.config/heroic/themes"|' "$cfg"
      fi
    '';
  };
}
