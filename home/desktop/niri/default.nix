# home/desktop/niri/default.nix - Niri WM + Noctalia shell configuration
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.niri;
in
{
  options.my.home.desktop.niri = {
    enable = mkEnableOption "Niri scrollable-tiling Wayland compositor";
  };

  config = mkIf cfg.enable {
    programs.niri.settings = {
      input = {
        keyboard = {
          xkb = {
            layout = "us";
            options = "ctrl:nocaps";
          };
          repeat-delay = 300;
          repeat-rate = 40;
        };
        touchpad = {
          tap = true;
          dwt = true;
          natural-scroll = true;
          click-method = "clickfinger";
          scroll-method = "two-finger";
        };
      };

      spawn-at-startup = [
        # Sync Wayland environment for D-Bus/systemd (required for portals)
        {
          command = [
            "dbus-update-activation-environment"
            "--systemd"
            "DISPLAY"
            "WAYLAND_DISPLAY"
            "XDG_CURRENT_DESKTOP"
            "NIXOS_OZONE_WL"
          ];
        }
        # Wallpaper daemon
        {
          command = [ "${inputs.awww.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/awww-daemon" ];
        }
      ];

      # Window appearance
      window-rules = [
        {
          geometry-corner-radius = {
            top-left = 10.0;
            top-right = 10.0;
            bottom-left = 10.0;
            bottom-right = 10.0;
          };
          clip-to-geometry = true;
        }
        {
          matches = [ { app-id = "dev.noctalia.Noctalia"; } ];
          open-floating = true;
          default-column-width = {
            fixed = 1080;
          };
          default-window-height = {
            fixed = 920;
          };
        }
      ];

      # Backdrop integration
      layer-rules = [
        {
          matches = [ { namespace = "^noctalia-backdrop"; } ];
          place-within-backdrop = true;
        }
      ];

      # Allow notification actions
      debug = {
        honor-xdg-activation-with-invalid-serial = true;
      };

      # Niri Navigation & Window Management Keybindings (Standard Defaults)
      binds = {
        # Help Menu
        "Mod+Shift+Slash".action.show-hotkey-overlay = { };

        # Core Applications
        "Mod+Return".action.spawn = [ "ghostty" ];
        "Mod+B".action.spawn = [ "zen-beta" ];
        "Mod+F".action.spawn = [ "thunar" ];
        "Mod+Shift+D".action.spawn = [ "vesktop" ];

        # Core Noctalia binds
        "Mod+Space".action.spawn = [
          "noctalia"
          "msg"
          "panel-toggle"
          "launcher"
        ];
        "Mod+S".action.spawn = [
          "noctalia"
          "msg"
          "panel-toggle"
          "control-center"
        ];
        "Mod+Comma".action.spawn = [
          "noctalia"
          "msg"
          "settings-toggle"
        ];
        "Super+Alt+L".action.spawn = [
          "noctalia"
          "msg"
          "session"
          "lock"
        ];

        # Audio & Brightness keys (managed by Noctalia)
        "XF86AudioRaiseVolume".action.spawn = [
          "noctalia"
          "msg"
          "volume-up"
        ];
        "XF86AudioLowerVolume".action.spawn = [
          "noctalia"
          "msg"
          "volume-down"
        ];
        "XF86AudioMute".action.spawn = [
          "noctalia"
          "msg"
          "volume-mute"
        ];
        "XF86MonBrightnessUp".action.spawn = [
          "noctalia"
          "msg"
          "brightness-up"
        ];
        "XF86MonBrightnessDown".action.spawn = [
          "noctalia"
          "msg"
          "brightness-down"
        ];

        # Window & Session Control
        "Mod+Q".action.close-window = { };
        "Mod+Shift+E".action.quit = { };
        "Ctrl+Alt+Delete".action.quit = { };

        # Overview
        "Mod+O".action.toggle-overview = { };

        # Focus Movement (Arrows and Vim-keys HJKL)
        "Mod+Left".action.focus-column-left = { };
        "Mod+Right".action.focus-column-right = { };
        "Mod+Down".action.focus-window-or-workspace-down = { };
        "Mod+Up".action.focus-window-or-workspace-up = { };
        "Mod+H".action.focus-column-left = { };
        "Mod+L".action.focus-column-right = { };
        "Mod+J".action.focus-window-or-workspace-down = { };
        "Mod+K".action.focus-window-or-workspace-up = { };

        # Column & Window Movement
        "Mod+Ctrl+Left".action.move-column-left = { };
        "Mod+Ctrl+Right".action.move-column-right = { };
        "Mod+Ctrl+Down".action.move-window-down = { };
        "Mod+Ctrl+Up".action.move-window-up = { };
        "Mod+Ctrl+H".action.move-column-left = { };
        "Mod+Ctrl+L".action.move-column-right = { };
        "Mod+Ctrl+J".action.move-window-down = { };
        "Mod+Ctrl+K".action.move-window-up = { };

        # Focus Monitor
        "Mod+Shift+Left".action.focus-monitor-left = { };
        "Mod+Shift+Right".action.focus-monitor-right = { };
        "Mod+Shift+Down".action.focus-monitor-down = { };
        "Mod+Shift+Up".action.focus-monitor-up = { };
        "Mod+Shift+H".action.focus-monitor-left = { };
        "Mod+Shift+L".action.focus-monitor-right = { };
        "Mod+Shift+J".action.focus-monitor-down = { };
        "Mod+Shift+K".action.focus-monitor-up = { };

        # Move Column to Monitor
        "Mod+Ctrl+Shift+Left".action.move-column-to-monitor-left = { };
        "Mod+Ctrl+Shift+Right".action.move-column-to-monitor-right = { };
        "Mod+Ctrl+Shift+Down".action.move-column-to-monitor-down = { };
        "Mod+Ctrl+Shift+Up".action.move-column-to-monitor-up = { };
        "Mod+Ctrl+Shift+H".action.move-column-to-monitor-left = { };
        "Mod+Ctrl+Shift+L".action.move-column-to-monitor-right = { };
        "Mod+Ctrl+Shift+J".action.move-column-to-monitor-down = { };
        "Mod+Ctrl+Shift+K".action.move-column-to-monitor-up = { };

        # Workspace switching (1-9)
        "Mod+1".action.focus-workspace = 1;
        "Mod+2".action.focus-workspace = 2;
        "Mod+3".action.focus-workspace = 3;
        "Mod+4".action.focus-workspace = 4;
        "Mod+5".action.focus-workspace = 5;
        "Mod+6".action.focus-workspace = 6;
        "Mod+7".action.focus-workspace = 7;
        "Mod+8".action.focus-workspace = 8;
        "Mod+9".action.focus-workspace = 9;

        # Switch to Workspace (Down/Up)
        "Mod+U".action.focus-workspace-down = { };
        "Mod+I".action.focus-workspace-up = { };
        "Mod+Page_Down".action.focus-workspace-down = { };
        "Mod+Page_Up".action.focus-workspace-up = { };

        # Move Column to Workspace (1-9)
        "Mod+Shift+1".action.move-column-to-workspace = 1;
        "Mod+Shift+2".action.move-column-to-workspace = 2;
        "Mod+Shift+3".action.move-column-to-workspace = 3;
        "Mod+Shift+4".action.move-column-to-workspace = 4;
        "Mod+Shift+5".action.move-column-to-workspace = 5;
        "Mod+Shift+6".action.move-column-to-workspace = 6;
        "Mod+Shift+7".action.move-column-to-workspace = 7;
        "Mod+Shift+8".action.move-column-to-workspace = 8;
        "Mod+Shift+9".action.move-column-to-workspace = 9;

        # Move Column to Workspace (Down/Up)
        "Mod+Ctrl+U".action.move-column-to-workspace-down = { };
        "Mod+Ctrl+I".action.move-column-to-workspace-up = { };
        "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = { };
        "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = { };

        # Move Workspace (Down/Up)
        "Mod+Shift+U".action.move-workspace-down = { };
        "Mod+Shift+I".action.move-workspace-up = { };
        "Mod+Shift+Page_Down".action.move-workspace-down = { };
        "Mod+Shift+Page_Up".action.move-workspace-up = { };

        # Consume/Expel windows to/from column
        "Mod+BracketLeft".action.consume-or-expel-window-left = { };
        "Mod+BracketRight".action.consume-or-expel-window-right = { };

        # Resize modes & Preset sizes
        "Mod+R".action.switch-preset-column-width = { };
        "Mod+Shift+R".action.switch-preset-column-width-back = { };
        "Mod+M".action.maximize-column = { };
        "Mod+Shift+F".action.fullscreen-window = { };
        "Mod+C".action.center-column = { };

        # Manual resizing
        "Mod+Minus".action.set-column-width = "-10%";
        "Mod+Equal".action.set-column-width = "+10%";
        "Mod+Shift+Minus".action.set-window-height = "-10%";
        "Mod+Shift+Equal".action.set-window-height = "+10%";
        "Mod+Ctrl+R".action.reset-window-height = { };

        # Floating window settings
        "Mod+V".action.toggle-window-floating = { };
        "Mod+Shift+V".action.switch-focus-between-floating-and-tiling = { };

        # Screenshots
        "Print".action.screenshot = {
          show-pointer = false;
        };
        "Alt+Print".action.screenshot-window = {
          show-pointer = false;
        };
        "Ctrl+Print".action.screenshot-screen = {
          show-pointer = false;
        };
      };
    };

    # Noctalia shell configuration
    programs.noctalia = {
      enable = true;
      systemd.enable = true;
      settings = {
        launch_apps_as_systemd_services = true;
        theme = {
          mode = "dark";
          source = "builtin";
          builtin = "Catppuccin";
        };
      };
    };

    # Clipboard history
    services.cliphist.enable = true;

    # Essential Wayland tooling
    home.packages = with pkgs; [
      inputs.awww.packages.${pkgs.stdenv.hostPlatform.system}.default
      xwayland-satellite
      wl-clipboard
      wl-mirror
      cliphist
      loupe
      grim
      slurp
      adwaita-icon-theme
      hyprpolkitagent
    ];
  };
}
