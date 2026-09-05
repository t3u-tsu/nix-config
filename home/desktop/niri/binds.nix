{
  config,
  ...
}:

{
  config = {
    programs.niri.settings.binds = {
      # Help Menu
      "Mod+Slash".action.show-hotkey-overlay = { };

      # Core Applications
      "Mod+Return".action.spawn = [ "ghostty" ];
      "Mod+B".action.spawn = [ "zen-beta" ];
      "Mod+F".action.spawn = [ "thunar" ];
      "Mod+D".action.spawn = [ "vesktop" ];

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
      "Mod+Alt+Left".action.move-column-left = { };
      "Mod+Alt+Right".action.move-column-right = { };
      "Mod+Alt+Down".action.move-window-down = { };
      "Mod+Alt+Up".action.move-window-up = { };
      "Mod+Alt+H".action.move-column-left = { };
      "Mod+Alt+L".action.move-column-right = { };
      "Mod+Alt+J".action.move-window-down = { };
      "Mod+Alt+K".action.move-window-up = { };

      # Focus Monitor
      "Mod+Ctrl+Left".action.focus-monitor-left = { };
      "Mod+Ctrl+Right".action.focus-monitor-right = { };
      "Mod+Ctrl+Down".action.focus-monitor-down = { };
      "Mod+Ctrl+Up".action.focus-monitor-up = { };
      "Mod+Ctrl+H".action.focus-monitor-left = { };
      "Mod+Ctrl+L".action.focus-monitor-right = { };
      "Mod+Ctrl+J".action.focus-monitor-down = { };
      "Mod+Ctrl+K".action.focus-monitor-up = { };

      # Move Column to Monitor
      "Mod+Alt+Ctrl+Left".action.move-column-to-monitor-left = { };
      "Mod+Alt+Ctrl+Right".action.move-column-to-monitor-right = { };
      "Mod+Alt+Ctrl+Down".action.move-column-to-monitor-down = { };
      "Mod+Alt+Ctrl+Up".action.move-column-to-monitor-up = { };
      "Mod+Alt+Ctrl+H".action.move-column-to-monitor-left = { };
      "Mod+Alt+Ctrl+L".action.move-column-to-monitor-right = { };
      "Mod+Alt+Ctrl+J".action.move-column-to-monitor-down = { };
      "Mod+Alt+Ctrl+K".action.move-column-to-monitor-up = { };

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
      "Mod+Ctrl+1".action.move-column-to-workspace = 1;
      "Mod+Ctrl+2".action.move-column-to-workspace = 2;
      "Mod+Ctrl+3".action.move-column-to-workspace = 3;
      "Mod+Ctrl+4".action.move-column-to-workspace = 4;
      "Mod+Ctrl+5".action.move-column-to-workspace = 5;
      "Mod+Ctrl+6".action.move-column-to-workspace = 6;
      "Mod+Ctrl+7".action.move-column-to-workspace = 7;
      "Mod+Ctrl+8".action.move-column-to-workspace = 8;
      "Mod+Ctrl+9".action.move-column-to-workspace = 9;

      # Move Column to Workspace (Down/Up)
      "Mod+Alt+U".action.move-column-to-workspace-down = { };
      "Mod+Alt+I".action.move-column-to-workspace-up = { };
      "Mod+Alt+Page_Down".action.move-column-to-workspace-down = { };
      "Mod+Alt+Page_Up".action.move-column-to-workspace-up = { };

      # Move Workspace (Down/Up)
      "Mod+Ctrl+U".action.move-workspace-down = { };
      "Mod+Ctrl+I".action.move-workspace-up = { };
      "Mod+Ctrl+Page_Down".action.move-workspace-down = { };
      "Mod+Ctrl+Page_Up".action.move-workspace-up = { };

      # Consume/Expel windows to/from column
      "Mod+BracketLeft".action.consume-or-expel-window-left = { };
      "Mod+BracketRight".action.consume-or-expel-window-right = { };

      # Resize modes & Preset sizes
      "Mod+R".action.switch-preset-column-width = { };
      "Mod+Ctrl+R".action.switch-preset-column-width-back = { };
      "Mod+M".action.maximize-column = { };
      "Mod+Shift+F".action.fullscreen-window = { };
      "Mod+C".action.center-column = { };
      "Mod+W".action.toggle-column-tabbed-display = { };

      # Manual resizing
      "Mod+Minus".action.set-column-width = "-10%";
      "Mod+Equal".action.set-column-width = "+10%";
      "Mod+Shift+Minus".action.set-window-height = "-10%";
      "Mod+Shift+Equal".action.set-window-height = "+10%";
      "Mod+Shift+R".action.reset-window-height = { };

      # Floating window settings
      "Mod+V".action.toggle-window-floating = { };
      "Mod+Ctrl+V".action.switch-focus-between-floating-and-tiling = { };

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
}
