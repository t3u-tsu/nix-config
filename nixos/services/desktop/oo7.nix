{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.services.desktop.oo7;
  # oo7-server 0.6.0 does not resolve /org/freedesktop/secrets/aliases/* in Unlock/Lock,
  # which causes go-keyring clients (such as gh) to treat the default collection as locked.
  oo7Server = pkgs.oo7-server.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./patches/oo7-resolve-alias-paths.patch ];
  });

  oo7InitCredential = pkgs.writeYshApplication {
    name = "oo7-init-credential";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.openssl
      config.systemd.package
    ];
    text = ''
      var config_home = get(ENV, 'XDG_CONFIG_HOME', "$[ENV.HOME]/.config")
      var cred_dir = "$config_home/credstore.encrypted"
      var cred_file = "$cred_dir/oo7.keyring-encryption-password"
      if test -e $cred_file {
        exit 0
      }
      install -d -m 0700 $cred_dir
      var tmp = "$cred_file.tmp"
      openssl rand -base64 32 | tr -d '\n' | systemd-creds encrypt --user --name=oo7.keyring-encryption-password - $tmp
      chmod 0600 $tmp
      mv $tmp $cred_file
    '';
  };
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
      dbus.packages = [ oo7Server ];
    };
    systemd.packages = [ oo7Server ];

    # The packaged user unit must not be overridden here: the unit relies on
    # ExecStart and ImportCredential=oo7.keyring-encryption-password.
    systemd.user = {
      targets.default.wants = [ "oo7-daemon.service" ];
      services.oo7-init-credential = {
        description = "Initialize encrypted oo7 keyring credential on first boot";
        before = [ "oo7-daemon.service" ];
        wantedBy = [
          "default.target"
          "oo7-daemon.service"
        ];
        unitConfig.ConditionPathExists = "!%E/credstore.encrypted/oo7.keyring-encryption-password";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${oo7InitCredential}/bin/oo7-init-credential";
        };
      };
    };

    programs.seahorse.enable = true;
    environment.systemPackages = [
      pkgs.oo7
      pkgs.libsecret
    ];
  };
}
