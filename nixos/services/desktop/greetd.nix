{
  pkgs,
  lib,
  config,
  ...
}:

with lib;
let
  cfg = config.my.services.desktop.greetd;
  greeterOutput = optionalAttrs (cfg.greeterOutput != null) { output = cfg.greeterOutput; };
in
{
  options.my.services.desktop.greetd = {
    enable = mkEnableOption "greetd with tuigreet";
    greeterOutput = mkOption {
      type = types.nullOr types.attrs;
      default = null;
      description = "Greeter output (connector) overrides, e.g. { name = \"eDP-1\"; }. Set per host.";
    };
  };

  config = mkIf cfg.enable {
    programs.noctalia-greeter = {
      enable = true;
      settings = {
        session = {
          default = "niri";
        };
        user = {
          default = config.my.user.name;
        };
        appearance = {
          # Sync wallpaper/palette/monitor layout from Noctalia when it runs.
          scheme = "Synced";
          corner_radius_scale = 1.0;
          power_buttons_position = "bottom-right";
          theme_mode = "dark";
          hide_logo = true;
          scheme_selector_position = "hidden";
        };
        keyboard = {
          layout = "us";
          options = "grp:alt_shift_toggle";
          numlock = false;
        };
        idle = {
          timeout = 300;
        };
        cursor = {
          theme = "Bibata-Modern-Amber";
          size = 24;
          path = "/run/current-system/sw/share/icons";
        };
      }
      // greeterOutput;
    };

    # Prevent session termination during 'nixos-rebuild switch'
    systemd.services.greetd.serviceConfig.X-RestartIfChanged = lib.mkForce false;

    # Unlock gnome-keyring on login
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.greetd.enableGnomeKeyring = true;
  };
}
