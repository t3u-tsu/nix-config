{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.home.desktop.communication;
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
      description = "Install the Thunderbird mail client.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      (lib.optional cfg.discord.enable pkgs.discord)
      ++ (lib.optional cfg.vesktop.enable pkgs.vesktop)
      ++ (lib.optional cfg.thunderbird.enable pkgs.thunderbird);
  };
}
