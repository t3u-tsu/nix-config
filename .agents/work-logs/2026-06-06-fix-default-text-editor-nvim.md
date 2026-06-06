# 作業ログ: ファイルマネージャからテキストファイルを開く際のデフォルトエディタを Neovim に設定

- 日付: 2026-06-06
- 作業ブランチ: `feature/assoc-nvim-text-files`

## 概要

ファイルマネージャ（Thunar等）でテキストファイルをクリックした際に、デフォルトで Neovim（nvim）が Ghostty ターミナル内で起動して開かれるように設定しました。また、CSVファイルに関しては LibreOffice Calc で開くように設定しました。

## 課題と原因

1. **Terminal=true に依存する desktop エントリの問題**:
   - NixOS や Home-manager の標準の `nvim.desktop` は `Terminal=true` が指定されています。
   - Niri 等の Wayland タイリングコンポジター環境下では、`Terminal=true` の場合に自動でターミナルエミュレータが起動する統合機能（`xdg-terminal-exec` など）が設定されておらず、ファイルマネージャからクリックしても Neovim が起動しない問題が発生します。
2. **他のテキスト関連 MIME タイプの不足**:
   - これまで `text/plain` にのみ `nvim.desktop` が関連付けられていましたが、Markdown やシェルスクリプト、JSON、YAML などの一般的なテキスト系ファイルが関連付けられていませんでした。

## 変更内容

### 1. カスタムデスクトップエントリの作成 (`modules/home/desktop/dev-tools/neovim.nix`)
- 標準の `nvim.desktop` に代わり、`ghostty -e nvim %F` を直接実行する `nvim-ghostty.desktop` デスクトップエントリを `xdg.desktopEntries.nvim-ghostty` として定義しました。
- これにより、`Terminal=false` としながらも Ghostty ターミナルを明示的に起動して Neovim を開くことができます。

### 2. XDG MIME アソシエーションの更新 (`modules/home/desktop/xdg.nix`)
- `text/plain` 以外の一般的なテキスト/コードファイル（Markdown、Shell、Python、Go、Rust、C、C++、JSON、JavaScript、XML、CSS、YAML、TOML、Nix、Lua、Log、INI、Properties、Makefile、Dockerfile、SQL、TypeScript、Ruby、Perl）の MIME タイプに対し、デフォルトアプリケーションとして `nvim-ghostty.desktop` を紐付けました。
- 一方、`text/csv` (CSVファイル) に関しては、ユーザーの好みに従い、表計算ソフトである `calc.desktop` (LibreOffice Calc) に関連付けました。

### 3. ドキュメントの更新
- `modules/home/desktop/dev-tools/README.md` および `README.ja.md` に、新しく追加した `nvim-ghostty` デスクトップエントリについての説明を追記しました。

## 検証方法

1. 構文チェック:
   `nix flake check` (成功済み)
2. ドライ実行:
   `sudo nixos-rebuild dry-activate --flake .#BrokenPC` (ユーザーにより実施予定)
3. 実機への適用 (要ユーザー承認):
   `sudo nixos-rebuild switch --flake .#BrokenPC`
4. 動作確認:
   - ファイルマネージャ（Thunar）から各種テキストファイル（`.txt`、`.md`、`.json`、`.nix` 等）をダブルクリックした際、Ghostty ターミナル内で Neovim が起動してファイルが開くことを確認する。
   - `.csv` ファイルをクリックした際に、LibreOffice Calc が起動することを確認する。
