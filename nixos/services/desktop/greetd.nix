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
  greeterWallpaperPath = "/var/lib/noctalia-greeter/wallpaper.jpg";
in
{
  options.my.services.desktop.greetd = {
    enable = mkEnableOption "greetd with tuigreet";
    greeterOutput = mkOption {
      type = types.nullOr types.attrs;
      default = null;
      description = "Greeter output (connector) overrides, e.g. { name = \"eDP-1\"; }. Set per host.";
    };
    greeterWallpaper = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Absolute path to a wallpaper image copied into the greeter state dir. Set per host.";
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
          # Noctalia Sync is not used here (prompted flow is noisy and
          # passwordless sync needs greeter >= 1.5.0), so pin the Vesper
          # dark palette and a matching background colour declaratively.
          scheme = "Synced";
          palette = {
            primary = "#FFC799";
            on_primary = "#000000";
            secondary = "#99FFE4";
            on_secondary = "#000000";
            tertiary = "#FBADFF";
            on_tertiary = "#000000";
            error = "#FF8080";
            on_error = "#000000";
            surface = "#0C0C0C";
            on_surface = "#FFFFFF";
            surface_variant = "#1C1C1C";
            on_surface_variant = "#A0A0A0";
            outline = "#505050";
            shadow = "#000000";
            hover = "#282828";
            on_hover = "#FFFFFF";
          };
          wallpaper = {
            path = if cfg.greeterWallpaper != null then greeterWallpaperPath else "color:#0C0C0C";
            fill_mode = "crop";
          };
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

    # The greeter runs as the 'greeter' user, so the cursor theme must be
    # available system-wide (not only under the login user's home).
    environment.systemPackages = [ pkgs.bibata-cursors ];

    # Copy the wallpaper into the greeter state dir because the greeter user
    # cannot traverse the login user's 0700 home (a symlink would not help).
    systemd.tmpfiles.rules = lib.optional (
      cfg.greeterWallpaper != null
    ) "C ${greeterWallpaperPath} 0640 greeter greeter - ${cfg.greeterWallpaper}";

    # Unlock gnome-keyring on login
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.greetd.enableGnomeKeyring = true;
  };
}
