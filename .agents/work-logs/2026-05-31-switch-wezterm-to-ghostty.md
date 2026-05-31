# 作業ログ: WezTerm から Ghostty (Flake 版) への移行および WezTerm 設定の完全削除

## 📅 日時
- 2026年5月31日

## 🎯 目的
- ターミナルエミュレータを `WezTerm` から `Ghostty` に完全に移行し、WezTerm に関連する設定ファイルを完全に削除する。
- Ghostty パッケージとして `nixpkgs` のものではなく、GitHub の `ghostty-org/ghostty` 公式 Flake から提供されるパッケージをオーバーレイ経由で利用する。
- Ghostty においても、壁紙（Noctalia/Matugen）から自動生成されるカラーテーマとの動的同期を維持する。
- Niri ウィンドウマネージャのショートカットキー（Mod+Return, Mod+Shift+E）で Ghostty が起動するように変更する。

## 🛠️ 変更内容

### 1. Flake inputs の追加とパッケージオーバーレイ設定 (`flake.nix` の変更)
- `inputs` に `ghostty = { url = "github:ghostty-org/ghostty"; inputs.nixpkgs.follows = "nixpkgs"; };` を追加しました。システム全体のパッケージ同期およびディスク容量節約を図るため、ローカルの `nixpkgs` に追従（follows）させています。
- `outputs` の `overlays` に、`ghostty = inputs.ghostty.packages.${prev.stdenv.hostPlatform.system}.default;` を定義するオーバーレイを追加。これにより、システム全体で flake 版の Ghostty を `pkgs.ghostty` として透過的に利用可能にしました。

### 2. WezTerm の完全削除
- `modules/home/desktop/dev-tools/wezterm.nix` を完全に削除。
- `modules/home/desktop/dev-tools/default.nix` の `imports` および `config` から WezTerm に関する設定をすべて削除。
- `modules/home/desktop/niri/noctalia/theme.nix` から `wezterm.lua.template` の定義と、`wezterm-colors` の自動生成タスク定義を完全に削除。

### 3. Ghostty バイナリキャッシュの追加とキャッシュ優先順位の最適化 (`modules/core/nix.nix` の変更)
- `nix.settings.extra-substituters` に `"https://ghostty.cachix.org?priority=30"` を追加。
- 提案されたキャッシュ優先順位設計に基づき、各サードパーティ製キャッシュ（ghostty, niri, nix-community, cuda, nix-gaming, chaotic-nyx）に適切な優先度パラメーター（`?priority=`）を設定し、評価の優先順位を整理しました。
- `nix.settings.extra-trusted-public-keys` の定義順も、`extra-substituters` と完全に一致するように並び替えて整理しました。
- これにより、専門ツールのキャッシュが最優先でクエリされるようになり、無駄なビルドの発生やクエリ遅延を極めて効率的に回避できるようになりました。

### 4. Ghostty の Home Manager モジュール定義
- 新しく `modules/home/desktop/dev-tools/ghostty.nix` を作成。
  - `programs.ghostty` を有効化し、`Noto Sans Mono CJK JP` フォント（サイズ12）、背景の不透明度（0.95）、ウィンドウのパディング（0）を設定。
  - ウィンドウデコレーションを無効化（`window-decorations = false`）し、シンプルな外観へ移行。
  - `config-file` オプションを用いて、Noctalia が動的生成する `~/.cache/noctalia/ghostty-colors` を読み込むように設定。

### 5. dev-tools カテゴリでの有効化制御
- `modules/home/desktop/dev-tools/default.nix` を変更。
  - `ghostty.nix` をインポート対象に追加。
  - `ghostty.enable` をデフォルトで `true` に設定。

### 6. Noctalia シェルによるカラーテーマ連携
- `modules/home/desktop/niri/noctalia/theme.nix` を変更。
  - Ghostty 用のカラー設定テンプレート `ghostty.template` を `~/.config/noctalia/templates/ghostty.template` に作成するように定義。
  - Noctalia が壁紙の色から生成したカラー設定を `~/.cache/noctalia/ghostty-colors` に出力するよう、`programs.noctalia-shell.settings.templates` に `ghostty-colors` を追加。

### 7. Niri ショートカットの変更
- `modules/home/desktop/niri/default.nix` を変更。
  - `Mod+Return` の起動対象を `wezterm` から `ghostty` に変更。
  - `Mod+Shift+E`（エディタ起動）の起動対象を `wezterm -e nvim` から `ghostty -e nvim` に変更。

### 8. 各種ドキュメントの更新
- `README.md` および `README.ja.md` において、主要機能のデスクトップ環境の説明を WezTerm から Ghostty へ更新（バイリンガル同期）。

## 🔧 トラブルシューティングと修正
初回の適用後、Ghostty 起動時に以下のエラーが発生したため、修正を行いました。

1. **`window-decorations` オプションのエラー**
   - **エラー**: `/home/t3u/.config/ghostty/config:5:window-decorations: unknown field`
   - **原因**: Ghostty の正しいオプション名は単数形の `window-decoration` であるため。
   - **対処**: `modules/home/desktop/dev-tools/ghostty.nix` のキー名を `window-decoration` に修正しました。

2. **Noctalia カラー設定ファイル未生成時の起動エラー**
   - **エラー**: `error opening config-file /home/t3u/.cache/noctalia/ghostty-colors: error.FileNotFound`
   - **原因**: 壁紙テーマエンジン（Noctalia Shell）が起動してカラーパレットを出力する前に Ghostty を起動すると、読み込み対象ファイルが存在せず致命的エラーとなって起動できないため。
   - **対処**: Ghostty の仕様に基づき、`config-file` のパスの前にプレフィックス `?` を付与して `?${config.home.homeDirectory}/.cache/noctalia/ghostty-colors` と設定しました。これにより、ファイルが存在しない場合でもエラーにせず、サイレントに無視して正常にデフォルト状態で起動できるようにしました。

## 🔍 検証結果
- 上記の修正を行った後、`nix flake check --impure` が正常に通過することを確認しました。

## 🚀 今後の適用手順
- 本ブランチ `feature/switch-wezterm-to-ghostty` を適用するために、以下のコマンドを実行する：
  ```bash
  sudo nixos-rebuild switch --flake .#BrokenPC
  ```
