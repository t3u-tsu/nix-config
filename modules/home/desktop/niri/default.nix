{ config, lib, pkgs, inputs, ... }:

with lib;
let
  cfg = config.my.home.desktop.niri;
in {
  options.my.home.desktop.niri = {
    enable = mkEnableOption "Niri Home Manager configuration";
  };

  imports = [
    ./noctalia.nix
    ./matugen.nix
    ./addons.nix
    ./power.nix
  ];

  config = mkIf cfg.enable {
    # Niri configuration based on niri-flake and official recommendations
    programs.niri.settings = {
      input = {
        keyboard.repeat-delay = 250;
        keyboard.repeat-rate = 30;
        touchpad = {
          tap = true;
          dwt = true;
          natural-scroll = true;
        };
      };

      layout = {
        gaps = 8;
        center-focused-column = "never";
        default-column-width = { proportion = 0.5; };
        
        # Border configuration (to be consistent with Dracula/Noctalia)
        focus-ring = {
          enable = true;
          width = 2;
          # We'll set colors via dynamic theming, but here are defaults
          active.color = "#bd93f9"; # Dracula Purple
          inactive.color = "#44475a"; # Dracula Comment
        };
      };

      # Essential startup sequence for Wayland environment synchronization
      spawn-at-startup = [
        # Sync environments for dbus and systemd users (Crucial for Noctalia & Portal)
        { command = [ "dbus-update-activation-environment" "--systemd" "DISPLAY" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP" "NIXOS_OZONE_WL" ]; }

        # Wallpaper daemon (Aww)
        { command = [ "${inputs.awww.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/awww-daemon" ]; }
        
        # Launch Noctalia Shell (Started via systemd, but we can also spawn it here for robustness)
        { command = [ "noctalia-shell" ]; }
      ];

      binds = {
        # --- Core Application Launchers (Primary) ---
        "Mod+Return".action.spawn = [ "alacritty" ];
        "Mod+Shift+B".action.spawn = [ "zen" ];
        "Mod+Shift+F".action.spawn = [ "nautilus" ];
        "Mod+Shift+E".action.spawn = [ "alacritty" "-e" "nvim" ];
        "Mod+Shift+V".action.spawn = [ "vesktop" ];
         
        # --- Launcher (Space is universal "open something") ---
        "Mod+Space".action.spawn = [ "noctalia-shell" "ipc" "call" "launcher" "toggle" ];
         
        # --- Window/Column Management (Clean & Explicit) ---
        "Mod+W".action.close-window = { };                           # Close Window
        "Mod+M".action.maximize-column = { };                        # Maximize Column
        "Mod+Shift+Space".action.toggle-column-tabbed-display = { }; # Tabbed Display
        "Mod+V".action.toggle-window-floating = { };                 # Toggle Floating
        
        # Column Resizing
        "Mod+R".action.switch-preset-column-width = { };
        "Mod+Shift+R".action.reset-window-height = { };
        "Mod+BracketLeft".action.consume-or-expel-window-left = { };
        "Mod+BracketRight".action.consume-or-expel-window-right = { };

        # --- Navigation (HJKL & Arrows) ---
        "Mod+H".action.focus-column-left = { };
        "Mod+L".action.focus-column-right = { };
        "Mod+K".action.focus-window-up = { };
        "Mod+J".action.focus-window-down = { };

        "Mod+Left".action.focus-column-left = { };
        "Mod+Right".action.focus-column-right = { };
        "Mod+Up".action.focus-window-up = { };
        "Mod+Down".action.focus-window-down = { };

        # --- Movement (Shift + Navigation) ---
        "Mod+Shift+H".action.move-column-left = { };
        "Mod+Shift+L".action.move-column-right = { };
        "Mod+Shift+K".action.move-window-up = { };
        "Mod+Shift+J".action.move-window-down = { };

        "Mod+Shift+Left".action.move-column-left = { };
        "Mod+Shift+Right".action.move-column-right = { };
        "Mod+Shift+Up".action.move-window-up = { };
        "Mod+Shift+Down".action.move-window-down = { };

        # --- Workspace Navigation ---
        "Mod+Page_Up".action.focus-workspace-up = { };
        "Mod+Page_Down".action.focus-workspace-down = { };
        "Mod+Shift+Page_Up".action.move-column-to-workspace-up = { };
        "Mod+Shift+Page_Down".action.move-column-to-workspace-down = { };
        
        # Numeric Workspace Access (Mod + 1-9)
        "Mod+1".action.focus-workspace = 1;
        "Mod+2".action.focus-workspace = 2;
        "Mod+3".action.focus-workspace = 3;
        "Mod+4".action.focus-workspace = 4;
        "Mod+5".action.focus-workspace = 5;
        "Mod+6".action.focus-workspace = 6;
        "Mod+7".action.focus-workspace = 7;
        "Mod+8".action.focus-workspace = 8;
        "Mod+9".action.focus-workspace = 9;

        # --- System Controls via Noctalia Shell IPC ---
        # Screen Capture
        "Print".action.spawn = [ "noctalia-shell" "ipc" "call" "screenshot" "captureOutput" ];
        "Mod+Print".action.spawn = [ "noctalia-shell" "ipc" "call" "screenshot" "captureArea" ];
        
        # Session & Power Menu
        "Mod+Escape".action.spawn = [ "noctalia-shell" "ipc" "call" "sessionMenu" "toggle" ];
        
        # Volume & Brightness (Synchronized with Noctalia OSD)
        "XF86AudioRaiseVolume".action.spawn = [ "noctalia-shell" "ipc" "call" "volume" "increase" ];
        "XF86AudioLowerVolume".action.spawn = [ "noctalia-shell" "ipc" "call" "volume" "decrease" ];
        "XF86AudioMute".action.spawn = [ "noctalia-shell" "ipc" "call" "volume" "muteOutput" ];
        "XF86AudioMicMute".action.spawn = [ "noctalia-shell" "ipc" "call" "volume" "muteInput" ];
        "XF86MonBrightnessUp".action.spawn = [ "noctalia-shell" "ipc" "call" "brightness" "increase" ];
        "XF86MonBrightnessDown".action.spawn = [ "noctalia-shell" "ipc" "call" "brightness" "decrease" ];

        # Media Playback Controls
        "XF86AudioPlay".action.spawn = [ "noctalia-shell" "ipc" "call" "media" "toggle" ];
        "XF86AudioNext".action.spawn = [ "noctalia-shell" "ipc" "call" "media" "next" ];
        "XF86AudioPrev".action.spawn = [ "noctalia-shell" "ipc" "call" "media" "previous" ];
         
        # Exit Niri
        "Mod+Shift+Q".action.quit = { };
      };

      window-rules = [
        # Floating windows
        {
          matches = [{ app-id = "org.keepassxc.KeePassXC"; }];
          open-floating = true;
        }
        # Vesktop: full-width (same as Zen for consistency)
        {
          matches = [{ app-id = "Vesktop"; }];
          default-column-width = { proportion = 1.0; };
        }
        # Zen Browser: full-width for web browsing comfort
        {
          matches = [{ app-id = "zen-beta"; }];
          default-column-width = { proportion = 1.0; };
        }
        # Bitwarden: floating password manager
        {
          matches = [{ app-id = "Bitwarden"; }];
          open-floating = true;
        }
      ];
    };

    home.packages = with pkgs; [
      inputs.awww.packages.${pkgs.stdenv.hostPlatform.system}.default
      xwayland-satellite
      matugen
      wl-clipboard
      cliphist
    ];
  };
}
