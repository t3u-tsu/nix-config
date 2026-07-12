# home/desktop/niri/default.nix - Minimal Niri WM + Noctalia shell configuration
# Settings reset to defaults for clean Niri experience.
# Re-customize binds, layout, and window-rules later as needed.
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
        keyboard.repeat-delay = 250;
        keyboard.repeat-rate = 30;
        touchpad = {
          tap = true;
          dwt = true;
          natural-scroll = true;
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
        # Noctalia shell
        { command = [ "noctalia" ]; }
      ];
    };

    # Noctalia shell (default config only; re-customize later)
    programs.noctalia.enable = true;

    # Clipboard history
    services.cliphist.enable = true;

    # Essential Wayland tooling
    home.packages = with pkgs; [
      inputs.awww.packages.${pkgs.stdenv.hostPlatform.system}.default
      xwayland-satellite
      wl-clipboard
      cliphist
      loupe
      grim
      slurp
      adwaita-icon-theme
      hyprpolkitagent
    ];
  };
}
