# 作業ログ: XDG Desktop Portal の設定調整によるファイル選択ダイアログ不具合の修正

- 日付: 2026-06-06
- 作業ブランチ: `feature/fix-portal-file-chooser`

## 概要

ブラウザ（FirefoxやZen Browser等）でファイルをアップロードする際、ファイル選択ダイアログ（FileChooser）が起動せず、アプリケーションがハングまたは無反応になる問題を解消しました。

## 課題と原因

1. **ファイル選択ダイアログが起動しない問題**:
   - `modules/services/desktop/niri.nix` にて、XDG Desktop Portal の共通設定が `config.common.default = [ "gnome" "gtk" ];` となっていました。
   - この設定では、ポータルの優先順位のトップが `gnome` (`xdg-desktop-portal-gnome`) となり、ファイル選択ダイアログ（`org.freedesktop.impl.portal.FileChooser`）の要求が GNOME ポータルに送られます。
   - `xdg-desktop-portal-gnome` のファイル選択ダイアログは GNOME Shell の内部 API（D-Bus）に依存しているため、GNOME 以外のデスクトップ環境（Niriなど）で実行されると、ダイアログを起動できずにハングまたはタイムアウトして動作しません。

## 変更内容

### 1. XDG Desktop Portal 設定の修正 (`modules/services/desktop/niri.nix`)
- `xdg.portal.config` をオブジェクト構造に変更し、`common` セクションを定義。
- `org.freedesktop.impl.portal.FileChooser` および `org.freedesktop.impl.portal.AppChooser` のポータルとして、GNOME環境外でも正しく動作する `gtk` (`xdg-desktop-portal-gtk`) を明示的に優先指定しました。

## 検証方法

1. 構文チェック:
   `nix flake check`
2. ドライ実行:
   `sudo nixos-rebuild dry-activate --flake .#BrokenPC`
3. 実機への適用 (要ユーザー承認):
   `sudo nixos-rebuild switch --flake .#BrokenPC`
4. 動作確認:
   - ブラウザから「ファイルをアップロード」などをクリックした際に、GTKベースのファイル選択ダイアログが正常に起動することを確認。
