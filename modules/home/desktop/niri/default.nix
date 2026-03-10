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
    ./addons.nix
    ./power.nix
  ];

  config = mkIf cfg.enable {
    programs.niri.settings = {
      input = {
        keyboard.repeat-delay = 250;
        keyboard.repeat-rate = 30;
        touchpad = {
          tap = true;
          dwt = true;
        };
      };

      layout = {
        gaps = 8;
        center-focused-column = "never";
        default-column-width = { proportion = 0.5; };
      };

      spawn-at-startup = [
        # Environment Synchronization for systemd/dbus
        { command = [ "dbus-update-activation-environment" "--systemd" "DISPLAY" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP" "NIXOS_OZONE_WL" ]; }

        # awww is the new swww from Codeberg
        { command = [ "${inputs.awww.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/awww-daemon" ]; }
        
        # Fcitx5 is now started as a Home Manager service, so we don't need to spawn it here.
      ];

      binds = {
        # --- Omarchy Inspired Bindings ---
        "Mod+Return".action.spawn = [ "alacritty" ];
        "Mod+Shift+B".action.spawn = [ "zen-beta" ];
        "Mod+Space".action.spawn = [ "noctalia-shell" "ipc" "call" "launcher" "toggle" ];
        "Mod+W".action.close-window = { };
        "Mod+F".action.maximize-column = { };
        "Mod+Shift+F".action.spawn = [ "nautilus" ];
        "Mod+V".action.toggle-window-floating = { };
        
        # --- Navigation (Vim-like HJKL & Arrow Keys) ---
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

        # --- Workspace Management ---
        "Mod+Page_Up".action.focus-workspace-up = { };
        "Mod+Page_Down".action.focus-workspace-down = { };
        "Mod+Shift+Page_Up".action.move-column-to-workspace-up = { };
        "Mod+Shift+Page_Down".action.move-column-to-workspace-down = { };
        
        # Direct Workspace Access (Super + 1-9)
        "Mod+1".action.focus-workspace = 1;
        "Mod+2".action.focus-workspace = 2;
        "Mod+3".action.focus-workspace = 3;
        "Mod+4".action.focus-workspace = 4;
        "Mod+5".action.focus-workspace = 5;
        "Mod+6".action.focus-workspace = 6;
        "Mod+7".action.focus-workspace = 7;
        "Mod+8".action.focus-workspace = 8;
        "Mod+9".action.focus-workspace = 9;

        # --- System & Media (Powered by Noctalia Shell IPC) ---
        "Print".action.spawn = [ "noctalia-shell" "ipc" "call" "screenshot" "captureOutput" ];
        "Mod+Shift+S".action.spawn = [ "noctalia-shell" "ipc" "call" "screenshot" "captureArea" ];
        "Mod+Shift+E".action.spawn = [ "noctalia-shell" "ipc" "call" "sessionMenu" "toggle" ];
        "Mod+Escape".action.spawn = [ "noctalia-shell" "ipc" "call" "sessionMenu" "toggle" ];
        
        # Audio & Brightness
        "XF86AudioRaiseVolume".action.spawn = [ "noctalia-shell" "ipc" "call" "volume" "increase" ];
        "XF86AudioLowerVolume".action.spawn = [ "noctalia-shell" "ipc" "call" "volume" "decrease" ];
        "XF86AudioMute".action.spawn = [ "noctalia-shell" "ipc" "call" "volume" "muteOutput" ];
        "XF86AudioMicMute".action.spawn = [ "noctalia-shell" "ipc" "call" "volume" "muteInput" ];
        "XF86MonBrightnessUp".action.spawn = [ "noctalia-shell" "ipc" "call" "brightness" "increase" ];
        "XF86MonBrightnessDown".action.spawn = [ "noctalia-shell" "ipc" "call" "brightness" "decrease" ];

        # Media Controls
        "XF86AudioPlay".action.spawn = [ "noctalia-shell" "ipc" "call" "media" "toggle" ];
        "XF86AudioNext".action.spawn = [ "noctalia-shell" "ipc" "call" "media" "next" ];
        "XF86AudioPrev".action.spawn = [ "noctalia-shell" "ipc" "call" "media" "previous" ];
      };

      window-rules = [
        {
          matches = [{ app-id = "org.keepassxc.KeePassXC"; }];
          open-floating = true;
        }
      ];
    };

    home.packages = with pkgs; [
      inputs.awww.packages.${pkgs.stdenv.hostPlatform.system}.default
      xwayland-satellite
      wl-clipboard
      cliphist
      # Redundant tools (brightnessctl, playerctl, grim, slurp) are removed
      # because Noctalia Shell handles these functions via IPC.
    ];
  };
}
