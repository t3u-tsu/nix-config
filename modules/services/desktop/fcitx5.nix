{ config, pkgs, lib, ... }:

{
  # システム全体の Fcitx5 設定
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        fcitx5-mozc
        kdePackages.fcitx5-qt
        fcitx5-gtk
        kdePackages.fcitx5-configtool
      ];
    };
  };

  # Wayland (Niri) 環境での互換性と安定性のため、
  # 不要な環境変数を「null」にして生成自体を抑制する（unset に相当）
  # 参照: https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland
  environment.sessionVariables = {
    GTK_IM_MODULE = lib.mkForce null;
    QT_IM_MODULE = lib.mkForce null;
    XMODIFIERS = lib.mkForce "@im=fcitx";
    SDL_IM_MODULE = lib.mkForce "fcitx";
    GLFW_IM_MODULE = lib.mkForce "ibus";
  };

  # ユーザーレベルの設定 (Home Manager)
  # 参照: https://zenn.dev/mityu/articles/nixos-fcitx5-mozc
  # 二重起動を避けるため、ここでは設定ファイルの生成のみを行い、サービスの起動はシステム側に任せる
  home-manager.users.${config.my.user.name}.i18n.inputMethod = {
    enabled = null; # enabled を無効化して設定注入のみ行う (NixOS の i18n モジュールとの重複回避)
    fcitx5.settings.inputMethod = {
      GroupOrder = { "0" = "Default"; };
      "Groups/0" = {
        Name = "Default";
        "Default Layout" = "jp";
        DefaultIM = "mozc";
      };
      "Groups/0/Items/0" = {
        Name = "keyboard-jp";
      };
      "Groups/0/Items/1" = {
        Name = "mozc";
      };
    };
  };
}
