{
  palette,
  homeDirectory,
  cursorTheme,
  cursorSize,
}:
let
  # Not part of the Vesper palette: the cast-target ring needs a darker shade of
  # palette.err so it still reads as the same warning while inactive.
  castInactive = "#7d0d2d";
in
''
  blur {
      passes 1
      offset 3.0
      noise 0.01
      saturation 1.5
  }

  animations {
      window-open {
          duration-ms 200
          curve "ease-out-expo"
      }
      window-close {
          duration-ms 150
          curve "ease-out-expo"
      }
      workspace-switch {
          spring damping-ratio=0.9 stiffness=1000 epsilon=0.0001
      }
      overview-open-close {
          spring damping-ratio=0.9 stiffness=1000 epsilon=0.0001
      }
  }

  input {
      keyboard {
          xkb {
              layout "us"
              model ""
              rules ""
              variant ""
              options "ctrl:nocaps"
          }
          repeat-delay 300
          repeat-rate 40
          track-layout "global"
      }
      touchpad {
          tap
          dwt
          natural-scroll
          scroll-method "two-finger"
          click-method "clickfinger"
      }
  }
  screenshot-path "${homeDirectory}/Pictures/Screenshots/%Y-%m-%d %H-%M-%S.png"
  prefer-no-csd
  overview {
      zoom 0.700000
      backdrop-color "${palette.bg}"
  }
  layout {
      gaps 16
      struts {
          left 0
          right 0
          top 0
          bottom 0
      }
      focus-ring {
          width 4
          urgent-color "${palette.err}"
          active-color "${palette.primary}"
          inactive-color "${palette.low}"
      }
      border {
          width 2
          urgent-color "${palette.err}"
          active-color "${palette.primary}"
          inactive-color "${palette.low}"
      }
      tab-indicator {
          on
          place-within-column
          width 3
          gap 4
          hide-when-single-tab
      }
      default-column-width { proportion 0.500000; }
      preset-column-widths {
          proportion 0.250000
          proportion 0.500000
          proportion 1.000000
      }
      preset-window-heights {
          proportion 0.500000
          proportion 0.750000
          proportion 1.000000
      }
      center-focused-column "never"
  }
  cursor {
      xcursor-theme "${cursorTheme}"
      xcursor-size ${toString cursorSize}
      hide-when-typing
      hide-after-inactive-ms 3000
  }
  hotkey-overlay {
      skip-at-startup
      hide-not-bound
  }
  clipboard { disable-primary; }
  gestures {
      hot-corners {
          top-left
      }
  }
  // Mod focuses and shapes columns, Mod+Ctrl moves the focused column/window,
  // Mod+Alt targets the other monitor (stand-in for niri's Mod+Shift), and
  // Mod+Shift launches apps.
  binds {
      Mod+H { focus-column-left; }
      Mod+J { focus-window-or-workspace-down; }
      Mod+K { focus-window-or-workspace-up; }
      Mod+L { focus-column-right; }
      Mod+Left { focus-column-left; }
      Mod+Down { focus-window-or-workspace-down; }
      Mod+Up { focus-window-or-workspace-up; }
      Mod+Right { focus-column-right; }
      Mod+Home { focus-column-first; }
      Mod+End { focus-column-last; }
      Mod+I { focus-workspace-up; }
      Mod+U { focus-workspace-down; }
      "Mod+Page_Up" { focus-workspace-up; }
      "Mod+Page_Down" { focus-workspace-down; }
      Mod+1 { focus-workspace 1; }
      Mod+2 { focus-workspace 2; }
      Mod+3 { focus-workspace 3; }
      Mod+4 { focus-workspace 4; }
      Mod+5 { focus-workspace 5; }
      Mod+6 { focus-workspace 6; }
      Mod+7 { focus-workspace 7; }
      Mod+8 { focus-workspace 8; }
      Mod+9 { focus-workspace 9; }
      Mod+Alt+H { focus-monitor-left; }
      Mod+Alt+J { focus-monitor-down; }
      Mod+Alt+K { focus-monitor-up; }
      Mod+Alt+L { focus-monitor-right; }
      Mod+Alt+Left { focus-monitor-left; }
      Mod+Alt+Down { focus-monitor-down; }
      Mod+Alt+Up { focus-monitor-up; }
      Mod+Alt+Right { focus-monitor-right; }
      Mod+Ctrl+H { move-column-left; }
      Mod+Ctrl+J { move-window-down; }
      Mod+Ctrl+K { move-window-up; }
      Mod+Ctrl+L { move-column-right; }
      Mod+Ctrl+Left { move-column-left; }
      Mod+Ctrl+Down { move-window-down; }
      Mod+Ctrl+Up { move-window-up; }
      Mod+Ctrl+Right { move-column-right; }
      Mod+Ctrl+Home { move-column-to-first; }
      Mod+Ctrl+End { move-column-to-last; }
      Mod+Ctrl+I { move-column-to-workspace-up; }
      Mod+Ctrl+U { move-column-to-workspace-down; }
      "Mod+Ctrl+Page_Up" { move-column-to-workspace-up; }
      "Mod+Ctrl+Page_Down" { move-column-to-workspace-down; }
      Mod+Ctrl+1 { move-column-to-workspace 1; }
      Mod+Ctrl+2 { move-column-to-workspace 2; }
      Mod+Ctrl+3 { move-column-to-workspace 3; }
      Mod+Ctrl+4 { move-column-to-workspace 4; }
      Mod+Ctrl+5 { move-column-to-workspace 5; }
      Mod+Ctrl+6 { move-column-to-workspace 6; }
      Mod+Ctrl+7 { move-column-to-workspace 7; }
      Mod+Ctrl+8 { move-column-to-workspace 8; }
      Mod+Ctrl+9 { move-column-to-workspace 9; }
      Mod+Alt+I { move-workspace-up; }
      Mod+Alt+U { move-workspace-down; }
      "Mod+Alt+Page_Up" { move-workspace-up; }
      "Mod+Alt+Page_Down" { move-workspace-down; }
      Mod+Ctrl+Alt+H { move-column-to-monitor-left; }
      Mod+Ctrl+Alt+J { move-column-to-monitor-down; }
      Mod+Ctrl+Alt+K { move-column-to-monitor-up; }
      Mod+Ctrl+Alt+L { move-column-to-monitor-right; }
      Mod+Ctrl+Alt+Left { move-column-to-monitor-left; }
      Mod+Ctrl+Alt+Down { move-column-to-monitor-down; }
      Mod+Ctrl+Alt+Up { move-column-to-monitor-up; }
      Mod+Ctrl+Alt+Right { move-column-to-monitor-right; }
      Mod+Equal { set-column-width "+10%"; }
      Mod+Minus { set-column-width "-10%"; }
      Mod+Alt+Equal { set-window-height "+10%"; }
      Mod+Alt+Minus { set-window-height "-10%"; }
      Mod+R { switch-preset-column-width; }
      Mod+Ctrl+R { switch-preset-column-width-back; }
      Mod+Alt+R { reset-window-height; }
      Mod+Ctrl+Alt+R { switch-preset-window-height; }
      Mod+BracketLeft { consume-or-expel-window-left; }
      Mod+BracketRight { consume-or-expel-window-right; }
      Mod+C { center-column; }
      Mod+F { maximize-column; }
      Mod+M { maximize-window-to-edges; }
      Mod+V { toggle-window-floating; }
      Mod+Ctrl+V { switch-focus-between-floating-and-tiling; }
      Mod+W { toggle-column-tabbed-display; }
      Mod+Alt+F { fullscreen-window; }
      Mod+Ctrl+Alt+F { toggle-windowed-fullscreen; }
      Alt+Tab { spawn "noctalia" "msg" "window-switcher"; }
      Mod+B { spawn "zen-beta"; }
      Mod+Shift+D { spawn "vesktop"; }
      Mod+Shift+F { spawn "thunar"; }
      Mod+Return { spawn "ghostty"; }
      Mod+Comma { spawn "noctalia" "msg" "settings-toggle"; }
      Mod+S { spawn "noctalia" "msg" "panel-toggle" "control-center"; }
      Mod+Space { spawn "noctalia" "msg" "panel-toggle" "launcher"; }
      Mod+O { toggle-overview; }
      Mod+Q { close-window; }
      Mod+Slash { show-hotkey-overlay; }
      Mod+Shift+E { quit; }
      Ctrl+Alt+Delete { quit; }
      Ctrl+Alt+L { spawn "noctalia" "msg" "session" "lock"; }
      Mod+Ctrl+N { spawn "noctalia" "msg" "nightlight-toggle"; }
      Mod+Ctrl+P { spawn "noctalia" "msg" "power-cycle"; }
      Print { screenshot show-pointer=false; }
      Ctrl+Print { screenshot-screen show-pointer=false; }
      Alt+Print { screenshot-window show-pointer=false; }
      Mod+P repeat=false { spawn-sh "wl-mirror $(niri msg --json focused-output | jq -r .name)"; }
      Mod+Alt+D { set-dynamic-cast-monitor; }
      Mod+Alt+S { set-dynamic-cast-window; }
      Mod+Alt+X { clear-dynamic-cast-target; }
      XF86AudioLowerVolume { spawn "noctalia" "msg" "volume-down"; }
      XF86AudioMute { spawn "noctalia" "msg" "volume-mute"; }
      XF86AudioRaiseVolume { spawn "noctalia" "msg" "volume-up"; }
      XF86MonBrightnessDown { spawn "noctalia" "msg" "brightness-down"; }
      XF86MonBrightnessUp { spawn "noctalia" "msg" "brightness-up"; }
  }
  spawn-at-startup "dbus-update-activation-environment" "--systemd" "DISPLAY" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP" "NIXOS_OZONE_WL"
  window-rule {
      opacity 0.950000
      background-effect {
          xray true
          blur true
      }
  }
  window-rule {
      geometry-corner-radius 10.000000 10.000000 10.000000 10.000000
      clip-to-geometry true
  }
  window-rule {
      match app-id="dev.noctalia.Noctalia"
      default-column-width { fixed 1080; }
      default-window-height { fixed 920; }
      open-floating true
  }
  window-rule {
      match app-id="^com.mitchellh.ghostty$"
      opacity 0.850000
      // Don't paint border/focus-ring as an opaque rect behind the window,
      // otherwise it blocks the translucency on unfocused windows.
      draw-border-with-background false
      // Terminal stays crisp: no blur/xray (background effect on/off per-rule).
      background-effect {
          xray false
          blur false
      }
  }
  window-rule {
      match app-id="^com.obsproject.Studio$"
      block-out-from "screencast"
  }
  window-rule {
      match app-id="^zen(-beta)?$"
      default-column-width { proportion 1.000000; }
      // Zen already renders its own translucency; niri's washes the pages out.
      opacity 1.000000
  }
  window-rule {
      match app-id="^(vesktop|Vesktop)$"
      default-column-width { proportion 1.000000; }
  }
  window-rule {
      match app-id="^(org\\.xfce\\.thunar|thunar|Thunar)$"
      default-column-display "tabbed"
  }
  window-rule {
      match is-window-cast-target=true
      focus-ring {
          active-color "${palette.err}"
          inactive-color "${castInactive}"
      }
      border {
          inactive-color "${castInactive}"
      }
      tab-indicator {
          active-color "${palette.err}"
          inactive-color "${castInactive}"
      }
  }
  layer-rule {
      match namespace="^noctalia-backdrop"
      place-within-backdrop true
  }
  debug { honor-xdg-activation-with-invalid-serial true; }
''
