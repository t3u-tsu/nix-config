{
  pkgs,
  lib,
  config,
  ...
}:

with lib;
let
  cfg = config.my.services.desktop.greetd;
in
{
  options.my.services.desktop.greetd = {
    enable = mkEnableOption "greetd with tuigreet";
  };

  config = mkIf cfg.enable {
    programs.noctalia-greeter = {
      enable = true;
      settings = {
        session = {
          default = "niri";
        };
        user = {
          # Open the password step for this user directly.
          default = config.my.user.name;
        };
        appearance = {
          # Sync wallpaper/palette/monitor layout from Noctalia when it runs.
          scheme = "Synced";
          # Fallback background (colour is readable by the greeter account).
          wallpaper = {
            path = "color:#0c0c0c";
            fill_mode = "crop";
          };
          corner_radius_scale = 1.0;
          password_style = "random";
          power_buttons_position = "bottom-right";
        };
        keyboard = {
          layout = "us";
          options = "grp:alt_shift_toggle";
          numlock = true;
        };
        idle = {
          timeout = 300;
        };
      };
    };

    # Prevent session termination during 'nixos-rebuild switch'
    systemd.services.greetd.serviceConfig.X-RestartIfChanged = lib.mkForce false;

    # Unlock gnome-keyring on login
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.greetd.enableGnomeKeyring = true;
  };
}
