{ config, lib, ... }:

let
  cfg = config.my.base.i18n;
in
{
  options.my.base.i18n = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "System-wide i18n and locale settings";
    };
    defaultLocale = lib.mkOption {
      type = lib.types.str;
      default = "ja_JP.UTF-8";
      description = "Default system locale";
    };
    supportedLocales = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "ja_JP.UTF-8/UTF-8"
        "en_US.UTF-8/UTF-8"
      ];
      description = "List of locales to generate";
    };
    consoleKeyMap = lib.mkOption {
      type = lib.types.str;
      default = "us";
      description = "Keymap for the system console";
    };
  };

  config = lib.mkIf cfg.enable {
    i18n = {
      inherit (cfg) defaultLocale supportedLocales;
    };

    console.keyMap = cfg.consoleKeyMap;
  };
}
