{ lib, ... }:

{
  # システム側の入力メソッド有効化を強制的にオフにする
  # これにより、Home-manager 側のみで Fcitx5 が起動するようにし、多重起動と環境変数の競合を防ぐ
  i18n.inputMethod.enable = lib.mkForce false;

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
