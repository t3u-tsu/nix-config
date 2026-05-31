{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.gpg-signing;
in
{
  options.my.home.desktop.gpg-signing = {
    enable = mkEnableOption "GPG signing with SOPS-managed key";
  };

  config = mkIf cfg.enable {
    sops.secrets.gpg_private_key = {
      sopsFile = ../../../secrets/services/signing.yaml;
    };

    services.gpg-agent = {
      enable = true;
      enableZshIntegration = true;
      pinentry.package = pkgs.pinentry-qt;
      defaultCacheTtl = 3600;
      maxCacheTtl = 86400;
    };

    home.activation.importGpgKey = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      GPG_KEY_PATH="${config.sops.secrets.gpg_private_key.path}"
      if [ -f "$GPG_KEY_PATH" ]; then
        $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --batch --import "$GPG_KEY_PATH" || true
      fi
    '';
  };
}
