{ pkgs, ... }:

{
  # システム全体のロケール設定
  # 日本語表示を可能にし、かつ物理キーボードは US 配列を使用します
  i18n = {
    defaultLocale = "ja_JP.UTF-8";
    supportedLocales = [
      "ja_JP.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
    ];
  };

  # コンソール（TTY）でのキーボードレイアウト設定
  console.keyMap = "us";
}
