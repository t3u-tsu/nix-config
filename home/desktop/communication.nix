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
            key = "9FC270ACC3631FB4";
            signByDefault = false;
          };
        };
      })
    ]
  );
}
