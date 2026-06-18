# 開発ツール設定

このディレクトリには、ユーザー固有の開発環境設定が含まれています。

## 📂 モジュール構成

- **`neovim.nix`**: Neovim のコア設定とエイリアス (`vi`, `vim`)、およびファイルマネージャ用のカスタムデスクトップエントリ (`nvim-ghostty`)。
- **`git-tools.nix`**: `lazygit` などのモダンな Git TUI ツール。
- **`ai-tools.nix`**: `gemini-cli` などの AI 支援開発ツール。
- **`vscode.nix`**: 拡張機能を宣言的に管理する Visual Studio Code のオプション設定。
- **`unity.nix`**: ゲーム開発用の Unity Hub。
- **`default.nix`**: 開発ツールの各カテゴリーの有効化を管理するインデックスモジュール。
