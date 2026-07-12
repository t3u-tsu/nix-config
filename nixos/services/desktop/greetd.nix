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
      };
    };

    # Prevent session termination during 'nixos-rebuild switch'
    systemd.services.greetd.serviceConfig.X-RestartIfChanged = lib.mkForce false;

    # Unlock gnome-keyring on login
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.greetd.enableGnomeKeyring = true;
  };
}
