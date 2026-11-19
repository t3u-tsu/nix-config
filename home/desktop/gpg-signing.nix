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
    enable = lib.mkEnableOption "GnuPG agent and agenix-managed key import";
  };

  config = lib.mkIf cfg.enable {
    programs = {
      gpg.enable = true;
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
