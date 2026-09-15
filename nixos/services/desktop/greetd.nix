{
  pkgs,
  lib,
  config,
  ...
}:

with lib;
let
  cfg = config.my.services.desktop.greetd;
  palette = import ../../../lib/palette.nix;
  greeterOutput = optionalAttrs (cfg.greeterOutput != null) { output = cfg.greeterOutput; };
  greeterWallpaperPath = "/var/lib/noctalia-greeter/wallpaper.jpg";

  # The greeter expects the complete Vesper set, upper case.
  greeterPalette = {
    primary = toUpper palette.primary;
    on_primary = toUpper palette.on_primary;
    secondary = toUpper palette.secondary;
    on_secondary = toUpper palette.on_secondary;
    tertiary = toUpper palette.tertiary;
    on_tertiary = toUpper palette.on_tertiary;
    error = toUpper palette.err;
    on_error = toUpper palette.on_error;
    surface = toUpper palette.bg;
    on_surface = toUpper palette.fg;
    surface_variant = toUpper palette.bg2;
    on_surface_variant = toUpper palette.fg2;
    outline = toUpper palette.low;
    shadow = toUpper palette.shadow;
    hover = toUpper palette.hover;
    on_hover = toUpper palette.on_hover;
  };
in
{
  options.my.services.desktop.greetd = {
    enable = mkEnableOption "greetd login manager with the Noctalia greeter";
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
    services.displayManager.noctalia-greeter = {
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
          # dark palette the same way the shell receives it.
          scheme = "Synced";
          palette = greeterPalette;
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
          options = "ctrl:nocaps";
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

    # The greeter user cannot traverse the login user's 0700 home, so the image
    # is copied into the greeter state dir. tmpfiles' C keeps the first copy
    # forever and would hide a swapped wallpaper, so re-copy on every boot.
    systemd.services.noctalia-greeter-wallpaper = lib.mkIf (cfg.greeterWallpaper != null) {
      description = "Copy the Noctalia greeter wallpaper into the greeter state dir";
      wantedBy = [ "greetd.service" ];
      before = [ "greetd.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.coreutils}/bin/install -o greeter -g greeter -m 0640 '${cfg.greeterWallpaper}' ${greeterWallpaperPath}";
      };
    };

    services.gnome.gnome-keyring.enable = true;
    security.pam.services.greetd.enableGnomeKeyring = true;
  };
}
