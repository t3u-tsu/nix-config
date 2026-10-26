{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.home.desktop.gpg-signing;
in
{
  options.my.home.desktop.gpg-signing = {
    enable = lib.mkEnableOption "GPG signing with an agenix-managed key";
  };

  config = lib.mkIf cfg.enable {
    programs = {
      gpg.enable = true;

      git.settings = {
        user.signingkey = "9FC270ACC3631FB4";
        commit.gpgsign = true;
        gpg.format = "openpgp";
      };
    };

    age.secrets.gpg_private_key = {
      rekeyFile = ../../secrets/master/services/signing/gpg_private_key.age;
    };

    services.gpg-agent = {
      enable = true;
      enableZshIntegration = true;
      pinentry.package = pkgs.pinentry-qt;
      defaultCacheTtl = 3600;
      maxCacheTtl = 86400;
    };

    systemd.user.services.import-gpg-key = {
      Unit = {
        Description = "Import the agenix-managed GPG signing key";
        After = [ "agenix.service" ];
        Requires = [ "agenix.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.gnupg}/bin/gpg --batch --import ${config.age.secrets.gpg_private_key.path}";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
