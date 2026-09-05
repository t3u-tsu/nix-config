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
        };
      };

      cursor = {
        theme = "Bibata-Modern-Amber";
        size = 24;
      };

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
