# 作業ログ: VLC 動画再生サイズ不具合の修正、Vesktop 設定の整理、および Thunar 最近使用したファイルの非表示化

- 日付: 2026-06-06
- 作業ブランチ: `feature/desktop-adjustments`

## 概要

VLCで高解像度動画を再生した際にウィンドウサイズが画面の縦幅を越えてはみ出す問題の修正、機能していなかった Vesktop のウィンドウルール設定のクリーンアップ、および Thunar 等の GTK アプリにおける「最近使用したファイル」項目の非表示化（GSettings/dconfおよびGTK3/4）を行いました。

## 課題と対応内容

1. **VLCのウィンドウサイズが画面外にはみ出す問題**:
   - VLCアプリ自体が動画のオリジナル解像度に基づいてウィンドウの強制リサイズを要求していることが判明しました。
   - **対策**: VLC自体の環境設定（ツール > 環境設定 > インターフェース）において、「ビデオのサイズにインターフェースをリサイズする (Resize interface to video size)」のチェックをオフにすることで、Niriのタイル枠内にスケーリングされはみ出さなくなりました。不要になった Niri 側の VLC ルールは削除しました。
2. **Vesktopのウィンドウルール整理**:
   - Vesktop 起動時の最大化や全幅タイル設定はうまく機能していなかったため、設定をクリーンアップし `window-rules` から Vesktop の項目を完全に削除しました。
3. **Thunar の「最近使用したファイル」の非表示化**:
   - Thunar（およびGTK3/4アプリケーション）のサイドバーやファイル選択ダイアログにある「最近使用したファイル（Recent）」を非表示にしたいという要望がありました。
   - 単に GTK 設定の `settings.ini` に書くだけでは、XDG Desktop Portal や GSettings/dconf 経由での履歴保存が有効なままであったため、履歴が書き込まれていました。
   - **対策**:
     - システム全体で `programs.dconf.enable = true` を有効化。
     - ユーザーの GSettings/dconf 設定で `"org/gnome/desktop/privacy" = { remember-recent-files = false; recent-files-max-age = 0; }` を適用し、ポータルやデスクトップレベルでの履歴追記も完全に無効化しました。

## 変更内容

- `modules/home/desktop/niri/default.nix`
  - `window-rules` から `Vesktop` および `vlc` / `org.videolan.vlc` のマッチングルールを完全に削除。
- `modules/services/desktop/niri.nix`
  - システムレベルで `programs.dconf.enable = true` を追加。
- `modules/home/desktop/theme.nix`
  - `gtk.gtk3.extraConfig` および `gtk.gtk4.extraConfig` に `gtk-recent-files-enabled = 0` など（整数値）を設定。
  - `dconf.settings` で `org/gnome/desktop/privacy` スキーマの `remember-recent-files = false` を設定。

## 検証方法

1. 構文チェック:
   `nix flake check`
2. 実機への適用（要ユーザー承認）:
   `sudo nixos-rebuild switch --flake .#BrokenPC`
