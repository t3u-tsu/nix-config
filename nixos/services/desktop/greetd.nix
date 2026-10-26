{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

let
  cfg = config.my.services.desktop.greetd;
  palette = import ../../../lib/palette.nix;
  greeterOutput = lib.optionalAttrs (cfg.greeterOutput != null) { output = cfg.greeterOutput; };
  greeterWallpaperPath = "/var/lib/noctalia-greeter/wallpaper.jpg";

  # The greeter expects the complete Vesper set, upper case.
  greeterPalette = {
    primary = lib.toUpper palette.primary;
    on_primary = lib.toUpper palette.on_primary;
    secondary = lib.toUpper palette.secondary;
    on_secondary = lib.toUpper palette.on_secondary;
    tertiary = lib.toUpper palette.tertiary;
    on_tertiary = lib.toUpper palette.on_tertiary;
    error = lib.toUpper palette.err;
    on_error = lib.toUpper palette.on_error;
    surface = lib.toUpper palette.bg;
    on_surface = lib.toUpper palette.fg;
    surface_variant = lib.toUpper palette.bg2;
    on_surface_variant = lib.toUpper palette.fg2;
    outline = lib.toUpper palette.low;
    shadow = lib.toUpper palette.shadow;
    hover = lib.toUpper palette.hover;
    on_hover = lib.toUpper palette.on_hover;
  };
in
{
  imports = [ inputs.noctalia-greeter.nixosModules.default ];

  options.my.services.desktop.greetd = {
    enable = lib.mkEnableOption "greetd login manager with the Noctalia greeter";
    greeterOutput = lib.mkOption {
      type = lib.types.nullOr (lib.types.attrsOf lib.types.anything);
      default = null;
      description = "Greeter output (connector) overrides, e.g. { name = \"eDP-1\"; }. Set per host.";
    };
    greeterWallpaper = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Absolute path to a wallpaper image copied into the greeter state dir. Set per host.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.displayManager.noctalia-greeter = {
      enable = true;
      settings = {
        session = {
          default = "niri";
        };
        user = {
          default = config.my.user.name;
        };
        auth = {
          allow_empty_password = true;
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
          theme = palette.cursor.name;
          size = palette.cursor.size;
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
        ExecStart = "${pkgs.coreutils}/bin/install -o greeter -g greeter -m 0640 ${lib.escapeShellArg cfg.greeterWallpaper} ${greeterWallpaperPath}";
      };
    };

    services.gnome.gnome-keyring.enable = true;
    programs.seahorse.enable = true;

    security.pam.services = {
      greetd = {
        enableGnomeKeyring = true;
        # Requires unix-early (inserted by enableGnomeKeyring) to populate PAM_AUTHTOK
        # first, allowing a single empty submission to fall through to fprintd immediately.
        rules.auth.unix.settings = {
          try_first_pass = lib.mkForce false;
          use_first_pass = lib.mkForce true;
        };
        rules.auth.fprintd.order = config.security.pam.services.greetd.rules.auth.unix.order + 10;
      };

      # Noctalia lock screen hardcodes the "login" PAM service and drives fprintd
      # directly over D-Bus, so strip pam_fprintd here to prevent duplicate prompts.
      login.fprintAuth = false;
    };
  };
}
