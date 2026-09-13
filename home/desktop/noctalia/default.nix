{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.noctalia;
  wallpaperDir = "${config.home.homeDirectory}/Pictures/wallpapers";
  isMinimal = cfg.wallpaperPreset == "minimal";
in
{
  options.my.home.desktop.noctalia = {
    enable = mkEnableOption "Noctalia Wayland shell (bar, launcher, notifications, wallpaper)";
    wallpaperPreset = mkOption {
      type = types.enum [
        "PTITSA"
        "ka256"
        "suzushiro"
        "minimal"
      ];
      default = "minimal";
      description = "Wallpaper slideshow preset (subfolder of ~/Pictures/wallpapers, or 'minimal' for a single static image)";
    };
  };

  config = mkIf cfg.enable {
    programs.noctalia = {
      enable = true;
      systemd.enable = true;

      settings = {
        shell = {
          # Noctalia needs a systemd user session (uwsm/niri-session) to launch
          # apps as services; niri here is started directly from greetd, so this
          # must stay off.
          launch_apps_as_systemd_services = false;
          polkit_agent = true;
          clipboard_keep_from_closed_apps = true;
          clipboard_history_max_entries = 100;
          clipboard_confirm_clear_history = true;
          clipboard_auto_paste = "auto";
          ui_scale = 1.0;
          corner_radius_scale = 1.0;
          settings_show_advanced = true;

          animation = {
            enabled = true;
            speed = 1.2;
          };

          launcher = {
            pinned = [
              "spotify"
              "org.kicad.kicad"
              "qucs-s"
              "thunderbird"
            ];
            show_app_actions = true;
            sort_by_usage = true;
          };

          panel = {
            transparency_mode = "glass";
            list_item_background = true;
          };
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
          fill_color = "surface";
          transition = [
            "zoom"
          ];
          transition_duration = 1500;
          transition_on_startup = true;
          edge_smoothness = 0.3;

          directory = if isMinimal then "" else "${wallpaperDir}/${cfg.wallpaperPreset}";
          fill_mode = if cfg.wallpaperPreset == "ka256" then "fit" else "crop";
          default.path = "${wallpaperDir}/PTITSA/144133008_p0.jpg";

          automation = {
            enabled = !isMinimal;
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

        bar = {
          default = {
            position = "top";
            thickness = 34;
            background_opacity = 0.85;
            padding = 14;
            widget_spacing = 6;
            radius = 12;
            shadow = true;
            capsule = true;
            start = [
              "launcher"
              "wallpaper"
              "workspaces"
              "group:sysmon_privacy"
            ];
            center = [ "clock" ];
            end = [
              "notifications"
              "clipboard"
              "group:net_bt"
              "volume"
              "brightness"
              "caffeine"
              "group:power_battery"
              "session"
            ];
            capsule_group = [
              {
                id = "sysmon_privacy";
                members = [
                  "sysmon"
                  "privacy"
                ];
              }
              {
                id = "net_bt";
                members = [
                  "network"
                  "bluetooth"
                ];
              }
              {
                id = "power_battery";
                members = [
                  "power_profile"
                  "battery"
                ];
              }
            ];
          };
        };

        # `type` is omitted: it equals the widget name for these built-ins.
        widget = {
          clock = {
            format = "{:%H:%M:%S}";
            actions = {
              left = "panel-toggle control-center home";
            };
          };
          workspaces = {
            style = "minimal";
            show_labels = true;
          };
          session = {
            glyph = "power";
          };
          volume = {
            show_label = true;
          };
          privacy = {
            hide_inactive = true;
          };
        };

        notification = {
          enable_daemon = true;
          position = "top_right";
          max_visible = 6;
          layer = "overlay";
          history_retention_hours = 168;
        };

        control_center = {
          sidebar = "compact";
          shortcuts = [
            { type = "wifi"; }
            { type = "bluetooth"; }
            { type = "caffeine"; }
            { type = "notification"; }
            { type = "wallpaper"; }
            { type = "power_profile"; }
          ];
        };

        weather = {
          enabled = true;
          refresh_minutes = 30;
          unit = "metric";
          effects = true;
        };

        location = {
          auto_locate = true;
        };
      };
    };

    # Heroic only reads ~/.config/heroic/themes when customThemesPath is set, so
    # seed it once while empty; jq avoids depending on Heroic's JSON formatting,
    # and the file stays user-editable afterwards.
    home.activation.heroicCustomThemesPath = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      cfg="$HOME/.config/heroic/config.json"
      if [ -f "$cfg" ] && ${pkgs.jq}/bin/jq -e '.customThemesPath == ""' "$cfg" >/dev/null 2>&1; then
        tmp="$(mktemp)"
        ${pkgs.jq}/bin/jq --arg p "${config.home.homeDirectory}/.config/heroic/themes" '.customThemesPath = $p' "$cfg" > "$tmp" && mv "$tmp" "$cfg"
      fi
    '';
  };
}
