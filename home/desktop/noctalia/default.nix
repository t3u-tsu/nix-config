{
  config,
  lib,
  pkgs,
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
          # Launch launcher/dock/taskbar apps as systemd services. Noctalia
          # needs to run in a systemd user session (uwsm/niri-session) for this
          # to take effect; here niri is started directly from greetd, so it
          # must stay off.
          launch_apps_as_systemd_services = false;
          # Register Noctalia's native polkit auth agent.
          polkit_agent = true;
          # Keep the live selection alive after its source app closes.
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
              "kicad"
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
            builtin_ids = [
              "ghostty"
              "starship"
              "wezterm"
            ];
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
          # Slideshow source: PTITSA set under the external Pictures dir.
          directory = "${config.home.homeDirectory}/Pictures/wallpapers/PTITSA";
          fill_mode = "crop";
          fill_color = "surface";
          transition = [
            "fade"
            "zoom"
            "wipe"
          ];
          transition_duration = 1500;
          transition_on_startup = true;
          edge_smoothness = 0.3;

          default = {
            path = "${config.home.homeDirectory}/Pictures/wallpapers/PTITSA/144133008_p0.jpg";
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

        # Top bar: launcher, workspaces, clipboard and wallpaper on the left;
        # clock and notifications centered; network, bluetooth, privacy, volume,
        # brightness, sysmon, power profile, battery, caffeine, power on the
        # right end (right-most is power).
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

        # Per-widget appearance. Two-digit seconds clock, minimal workspace
        # pills with labels, power-glyph session button, volume shows its
        # label. `type` equals the name for these built-ins, so it is omitted.
        widget = {
          clock = {
            format = "{:%H:%M:%S}";
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

        # Notification daemon (currently only internal toasts fire).
        notification = {
          enable_daemon = true;
          position = "top_right";
          max_visible = 6;
          layer = "overlay";
          history_retention_hours = 168;
        };

        control_center = {
          sidebar = "compact";
          # Home quick actions: swapped Night Light for Wallpaper.
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

    # Heroic reads its custom themes from customThemesPath; when unset it does
    # not scan ~/.config/heroic/themes, so the Noctalia matugen theme stays
    # invisible. Seed it once (only while empty), via jq so we do not depend on
    # Heroic's JSON whitespace/formatting, and keep it user-editable.
    home.activation.heroicCustomThemesPath = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      cfg="$HOME/.config/heroic/config.json"
      if [ -f "$cfg" ] && ${pkgs.jq}/bin/jq -e '.customThemesPath == ""' "$cfg" >/dev/null 2>&1; then
        tmp="$(mktemp)"
        ${pkgs.jq}/bin/jq --arg p "${config.home.homeDirectory}/.config/heroic/themes" '.customThemesPath = $p' "$cfg" > "$tmp" && mv "$tmp" "$cfg"
      fi
    '';
  };
}
