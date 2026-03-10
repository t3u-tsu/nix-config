{ config, lib, ... }:

with lib;
let
  cfg = config.my.core.i18n;
in {
  options.my.core.i18n = {
    enable = mkEnableOption "System-wide i18n and locale settings" // { default = true; };
    defaultLocale = mkOption {
      type = types.str;
      default = "ja_JP.UTF-8";
      description = "Default system locale";
    };
    supportedLocales = mkOption {
      type = types.listOf types.str;
      default = [ "ja_JP.UTF-8/UTF-8" "en_US.UTF-8/UTF-8" ];
      description = "List of locales to generate";
    };
    consoleKeyMap = mkOption {
      type = types.str;
      default = "us";
      description = "Keymap for the system console";
    };
  };

  config = mkIf cfg.enable {
    i18n = {
      defaultLocale = cfg.defaultLocale;
      supportedLocales = cfg.supportedLocales;
    };

    console.keyMap = cfg.consoleKeyMap;
  };
}
