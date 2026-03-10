{ config, pkgs, ... }:

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

  # ユーザーレベルの設定 (Home Manager)
  # 参照: https://zenn.dev/mityu/articles/nixos-fcitx5-mozc
  # これにより Mozc がデフォルトで有効化され、宣言的に管理される
  home-manager.users.${config.my.user.name}.i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      addons = [ pkgs.fcitx5-mozc ];
      settings.inputMethod = {
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
  };
}
