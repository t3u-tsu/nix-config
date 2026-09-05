{
  config,
  ...
}:

let
  palette = import ../palette.nix;
in
{
  config = {
    programs.niri.settings = {
      prefer-no-csd = true;

      layout = {
        default-column-width = {
          proportion = 0.5;
        };
        focus-ring = {
          active = {
            color = palette.primary;
          };
          inactive = {
            color = palette.low;
          };
          urgent = {
            color = palette.err;
          };
        };
        # Window borders (prefer-no-csd + corner-radius + clip-to-geometry).
        border = {
          enable = true;
          width = 2;
          active = {
            color = palette.primary;
          };
          inactive = {
            color = palette.low;
          };
          urgent = {
            color = palette.err;
          };
        };
        # Preset column widths cycled by Mod+R.
        preset-column-widths = [
          { proportion = 0.25; }
          { proportion = 0.5; }
          { proportion = 1.0; }
        ];
        preset-window-heights = [
          { proportion = 0.5; }
          { proportion = 0.75; }
          { proportion = 1.0; }
        ];
      };

      cursor = {
        theme = "Bibata-Modern-Amber";
        size = 24;
        hide-when-typing = true;
        hide-after-inactive-ms = 3000;
      };

      animations = {
        window-open.enable = true;
        window-close.enable = true;
        workspace-switch.enable = true;
        overview-open-close.enable = true;
      };

      overview = {
        zoom = 0.7;
        backdrop-color = palette.bg;
      };

      clipboard = {
        disable-primary = true;
      };

      hotkey-overlay = {
        skip-at-startup = true;
        hide-not-bound = true;
      };

      screenshot-path = "${config.home.homeDirectory}/Pictures/Screenshots/%Y-%m-%d %H-%M-%S.png";

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
      ];

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
        {
          matches = [ { app-id = "^com.mitchellh.ghostty$"; } ];
          opacity = 0.95;
        }
        # OBS : hide content from screen capture
        {
          matches = [
            { app-id = "^com.obsproject.Studio$"; }
          ];
          block-out-from = "screencast";
        }
        # Zen Browser
        {
          matches = [ { app-id = "^zen(-beta)?$"; } ];
          default-column-width = {
            proportion = 1.0;
          };
        }
        # Vesktop
        {
          matches = [ { app-id = "^(vesktop|Vesktop)$"; } ];
          default-column-width = {
            proportion = 1.0;
          };
        }
      ];

      # Backdrop integration (Noctalia overview backdrop)
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
    };
  };
}
