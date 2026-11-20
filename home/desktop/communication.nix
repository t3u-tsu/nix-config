{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.home.desktop.communication;
  privateAccounts = import (inputs.nix-config-private + "/thunderbird/accounts.nix");
  thunderbirdGpgKeyId = "9FC270ACC3631FB4";
  thunderbirdGpgFingerprint = "da73ecf644104695d36f4e8c9fc270acc3631fb4";
  thunderbirdGpgPublicKey = pkgs.writeText "thunderbird-gpg-pubkey.asc" ''
    -----BEGIN PGP PUBLIC KEY BLOCK-----

    mDMEaaPP2BYJKwYBBAHaRw8BAQdAqdAkixkcJkHccergoEP0sB4zzbqHUB9Nf3qC
    mARy14i0EHQzdSA8dDN1QHQzdS51az6IkAQTFgoAOBYhBNpz7PZEEEaV029OjJ/C
    cKzDYx+0BQJpo8/YAhsDBQsJCAcCBhUKCQgLAgQWAgMBAh4BAheAAAoJEJ/CcKzD
    Yx+0FcUBAIGt4AVakEVF9rkgxAy+rP0buffhqpP6ipDrZ88njKd0AQCX3f64Ibif
    AVO62gkT9H813B0FeRc71Ggr5QVMy7XNA7g4BGmjz9gSCisGAQQBl1UBBQEBB0Di
    /uSrSDi6ryIMD4N/eUJ5V5xcCvPRAKd0hAEuIGx2CQMBCAeIeAQYFgoAIBYhBNpz
    7PZEEEaV029OjJ/CcKzDYx+0BQJpo8/YAhsMAAoJEJ/CcKzDYx+0QJgA/1XRjUiX
    wxuuyV1nE95uco2AbW799Cu8vRgIuoFeUcv/AP4i15jXfrGCYcrbpwXzMy3rc5GA
    ZArbk1XJbkTRzQYMDA==
    =H5EP
    -----END PGP PUBLIC KEY BLOCK-----
  '';
in
{
  options.my.home.desktop.communication = {
    enable = lib.mkEnableOption "Communication tools";
    discord.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install the official Discord client.";
    };
    vesktop.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install Vesktop, a third-party Discord client.";
    };
    thunderbird.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable declarative Thunderbird mail client configuration.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages =
          (lib.optional cfg.discord.enable pkgs.discord) ++ (lib.optional cfg.vesktop.enable pkgs.vesktop);
      }
      (lib.mkIf cfg.thunderbird.enable {
        programs.thunderbird = {
          enable = true;
          profiles.default = {
            isDefault = true;
            withExternalGnupg = true;
            settings = {
              "mail.openpgp.fetch_pubkeys_from_gnupg" = true;
              "mail.identity.default.attach_public_key" = true;
            };
          };
        };

        accounts.email.accounts.primary = privateAccounts.primary // {
          primary = true;
          thunderbird = {
            enable = true;
            profiles = [ "default" ];
          };
          gpg = {
            key = thunderbirdGpgKeyId;
            signByDefault = false;
          };
        };

        home.activation.thunderbirdOpenPgpKey = config.lib.dag.entryAfter [ "writeBoundary" ] ''
          if [ -z "''${DRY_RUN:-}" ]; then
            profileDir="$HOME/.thunderbird/default"
            pubring="$profileDir/pubring.gpg"
            db="$profileDir/openpgp.sqlite"
            mkdir -p "$profileDir"

            if [ ! -f "$pubring" ]; then
              ${pkgs.gnupg}/bin/gpg --dearmor < ${thunderbirdGpgPublicKey} > "$pubring"
            elif ! ${pkgs.gnupg}/bin/gpg --no-default-keyring --keyring "$pubring" --list-keys "${thunderbirdGpgKeyId}" >/dev/null 2>&1; then
              ${pkgs.gnupg}/bin/gpg --no-default-keyring --keyring "$pubring" --batch --import ${thunderbirdGpgPublicKey}
            fi

            if [ ! -f "$db" ] || ! ${pkgs.sqlite}/bin/sqlite3 "$db" "SELECT 1 FROM acceptance_decision WHERE fpr='${thunderbirdGpgFingerprint}' LIMIT 1;" 2>/dev/null | grep -q 1; then
              ${pkgs.sqlite}/bin/sqlite3 "$db" "CREATE TABLE IF NOT EXISTS acceptance_email (fpr text not null, email text not null, unique(fpr, email)); CREATE TABLE IF NOT EXISTS acceptance_decision (fpr text not null, decision text not null, unique(fpr)); CREATE UNIQUE INDEX IF NOT EXISTS acceptance_email_i1 on acceptance_email(fpr, email); CREATE UNIQUE INDEX IF NOT EXISTS acceptance__decision_i1 on acceptance_decision(fpr); INSERT OR IGNORE INTO acceptance_email VALUES('${thunderbirdGpgFingerprint}', '${privateAccounts.primary.address}'); INSERT OR IGNORE INTO acceptance_decision VALUES('${thunderbirdGpgFingerprint}', 'unverified');"
            fi
          fi
        '';
      })
    ]
  );
}
