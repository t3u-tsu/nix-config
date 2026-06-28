# 開発ツール設定

このディレクトリには、ユーザー固有の開発環境設定が含まれています。

## 📂 モジュール構成

- **`neovim.nix`**: Neovim のコア設定とエイリアス (`vi`, `vim`)、およびファイルマネージャ用のカスタムデスクトップエントリ (`nvim-ghostty`)。
- **`git-tools.nix`**: `lazygit` などのモダンな Git TUI ツール。
- **`ai-tools.nix`**: `CodeWhale` や `GitHub Copilot` などの AI 支援開発ツール。
- **`hardware.nix`**: KiCad や picocom などのハードウェア開発ツール。WCH-LinkE（ch32fun）書き込み・デバッグ用のシステム層 udev ルールもあわせて統合します。
- **`ghostty.nix`**: Ghostty ターミナルの設定。
- **`unity.nix`**: ゲーム開発用の Unity Hub。
- **`default.nix`**: 開発ツールの各カテゴリーの有効化を管理するインデックスモジュール。
