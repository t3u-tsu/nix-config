{ pkgs, lib, ... }:

{
  # システム全体の Fcitx5 パッケージ提供
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

  # Wayland (Niri) 互換性のための環境変数クリア
  # これにより GTK/QT アプリケーションが Wayland ネイティブの入力を優先するようになる
  environment.sessionVariables = {
    GTK_IM_MODULE = lib.mkForce null;
    QT_IM_MODULE = lib.mkForce null;
    XMODIFIERS = lib.mkForce "@im=fcitx";
    SDL_IM_MODULE = lib.mkForce "fcitx";
    GLFW_IM_MODULE = lib.mkForce "ibus";
  };
}
