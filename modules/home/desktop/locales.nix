{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.my.home.desktop.locales;
in {
  options.my.home.desktop.locales = {
    enable = mkEnableOption "User-specific locale and input method settings";
    inputMethod = mkOption {
      type = types.enum [ "fcitx5" "none" ];
      default = "fcitx5";
      description = "User-specific input method";
    };
    keyboardLayout = mkOption {
      type = types.str;
      default = "us";
      description = "Keyboard layout for the input method (e.g., 'us', 'jp')";
    };
  };

  config = mkIf cfg.enable {
    home.language.base = "ja_JP.UTF-8";

    # Fcitx5 ユーザープロファイル設定 (宣言的に Mozc を有効化)
    # 参照: https://zenn.dev/mityu/articles/nixos-fcitx5-mozc
    # システム側の i18n.inputMethod と役割を分担し、こちらはプロファイルの生成のみを行う
    i18n.inputMethod = mkIf (cfg.inputMethod == "fcitx5") {
      enable = true;
      type = "fcitx5";
      fcitx5.settings.inputMethod = {
        GroupOrder = { "0" = "Default"; };
        "Groups/0" = {
          Name = "Default";
          "Default Layout" = cfg.keyboardLayout;
          DefaultIM = "mozc";
        };
        "Groups/0/Items/0" = {
          Name = "keyboard-${cfg.keyboardLayout}";
        };
        "Groups/0/Items/1" = {
          Name = "mozc";
        };
      };
    };
  };
}
