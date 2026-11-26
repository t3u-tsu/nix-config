{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.services.desktop.oo7;
in
{
  options.my.services.desktop.oo7 = {
    enable = lib.mkEnableOption "oo7 Freedesktop Secret Service daemon";
  };

  config = lib.mkIf cfg.enable {
    services = {
      # Override niri-flake's gnome-keyring (and its gcr-ssh-agent) so oo7-daemon
      # owns org.freedesktop.secrets without D-Bus or SSH agent conflicts.
      gnome = {
        gnome-keyring.enable = lib.mkForce false;
        gcr-ssh-agent.enable = lib.mkForce false;
      };
      dbus.packages = [ pkgs.oo7-server ];
    };
    systemd.packages = [ pkgs.oo7-server ];

    # The packaged user unit must not be overridden here: the unit relies on
    # ExecStart and ImportCredential=oo7.keyring-encryption-password.
    systemd.user.targets.default.wants = [ "oo7-daemon.service" ];

    programs.seahorse.enable = true;
    environment.systemPackages = [
      pkgs.oo7
      pkgs.libsecret
    ];
  };
}
