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
  };

  config = mkIf cfg.enable {
    home.packages =
      (optional cfg.discord.enable pkgs.discord) ++ (optional cfg.vesktop.enable pkgs.vesktop);

    # Vesktop (Vencord) will automatically pick up the theme generated
    # by Noctalia Shell templates in Step 7.
    # No extra Nix code needed here as long as the file exists,
    # but we can add Vesktop-specific tweaks if needed.
  };
}
