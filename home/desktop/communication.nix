{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.communication;
in
{
  options.my.home.desktop.communication = {
    enable = mkEnableOption "Communication tools";
    discord.enable = mkOption {
      type = types.bool;
      default = false;
    };
    vesktop.enable = mkOption {
      type = types.bool;
      default = true;
    };
    thunderbird.enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages =
      (optional cfg.discord.enable pkgs.discord)
      ++ (optional cfg.vesktop.enable pkgs.vesktop)
      ++ (optional cfg.thunderbird.enable pkgs.thunderbird);
  };
}
