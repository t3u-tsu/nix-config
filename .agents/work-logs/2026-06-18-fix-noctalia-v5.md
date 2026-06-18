# 作業ログ: Noctalia v5 移行に伴うオプション・バイナリ名の修正

- 日付: 2026-06-18
- 作業ブランチ: `feature/fix-noctalia-v5`

## 概要

自動アップデート（`flake.lock` 更新）によって `noctalia-shell` のリビジョンが更新され、v5 への移行が行われました。これに伴い、オプション構造およびバイナリ名が変更され、CIの `nix flake check` が失敗していた問題を解消するため、関連する設定を修正しました。

## 課題と原因

GitHub Actions 側で以下のエラーが発生していました。
```
error: The option `home-manager.users.t3u.programs.noctalia-shell' does not exist.
```
`noctalia-shell` のアップストリーム更新（v5）により、以下の仕様変更が発生していました。
1. Home-manager オプションパスが `programs.noctalia-shell` から `programs.noctalia` に変更。
2. 実行バイナリ名（`mainProgram`）が `noctalia-shell` から `noctalia` に変更。
3. Systemd ユーザーサービス名が `noctalia-shell` から `noctalia` に変更。

## 変更内容

### 1. Home-manager オプションパスの修正
以下のファイルで、オプション名を `programs.noctalia-shell` から `programs.noctalia` に修正しました。
* `modules/home/desktop/niri/noctalia/default.nix`
* `modules/home/desktop/niri/noctalia/theme.nix`
* `modules/home/desktop/niri/noctalia/ui.nix`

### 2. コマンド名およびシステム定義の修正
以下のファイルで、バイナリ名 `noctalia-shell` を `noctalia` に修正しました。また、Systemd サービス名 `noctalia-shell` を `noctalia` に修正しました。
* `modules/home/desktop/niri/default.nix` (ショートカット、自動起動、Systemd 設定の `noctalia` へのリネーム)
* `modules/home/desktop/niri/power.nix` (hypridle の `lock_cmd` コマンド名の更新)

## 検証方法

1. 構文チェック:
   `nix flake check` (成功)
