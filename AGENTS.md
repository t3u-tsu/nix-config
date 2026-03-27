# NixOS 設定構築 - 運用・開発ガイド

このドキュメントは、本リポジトリの設計思想、開発ワークフロー、および作業履歴を管理するためのものです。

---

## 🚀 プロジェクト概要

本リポジトリは、**Niri + Noctalia Shell** を中核とした、宣言的で高度にカスタマイズされたデスクトップ環境の構築を目指しています。

- **OS**: NixOS (Unstable)
- **WM**: Niri (Scrollable-Tiling)
- **Shell**: Noctalia Shell (Custom Quickshell)
- **Theme**: Dracula / Catppuccin (Managed via Matugen)

---

## 🛠️ 開発ワークフロー

### 1. 作業の基本ルール
- **ブランチ戦略**: 直接 `main` にコミットせず、`feature/<name>` または `refactor/<name>` ブランチを作成してください。
- **対話言語**: ユーザーへの報告、相談はすべて **日本語** で行います。
- **ドキュメント優先**: 変更の際は `TODO.md` や `README.md` との整合性を常に確認してください。

### 2. 変更・適用手順
1.  **ブランチ作成**: `git checkout -b feature/topic-name`
2.  **実装**: 必要な Nix ファイルを編集。
3.  **検証**:
    - `nix flake check`
    - `sudo nixos-rebuild dry-activate --flake .#BrokenPC`
4.  **適用**: `sudo nixos-rebuild switch --flake .#BrokenPC`
5.  **記録**: `.agents/work-logs/` に作業ログを作成し、`AGENTS.md` の履歴を更新。

---

## 📖 構成ディレクトリ構造

- `modules/core/`: システム基盤（Network, Sops, Nix）
- `modules/home/`: ユーザー環境（Home-manager）
    - `desktop/`: GUI アプリ、WM (Niri/Noctalia)
    - `shell/`: Zsh, Starship, CLI ツール
- `hosts/`: マシン固有の定義
- `secrets/`: SOPS による機密情報管理

---

## 📋 最近の活動記録 (Activity Summary)

- **2026-03-28**: Noctalia UI 最適化、スクショ修正、および LibreOffice の導入。
- **2026-03-27**: Noctalia Shell 構成の高度化、Spotify テーマ適用。
- **2026-03-10**: Niri への完全移行実施、greetd 導入。

---

## 📜 過去の履歴とログ
詳細は [作業ログのディレクトリ](./.agents/work-logs/) を参照してください。

### 各セッションの詳細ログ（抜粋）
- [2026-03-28: デスクトップ最適化 Phase 2 & クリーンアップ](./.agents/work-logs/2026-03-28-desktop-fixes-v2.md)
- [2026-03-27: デスクトップ最適化 Phase 1](./.agents/work-logs/2026-03-27-desktop-optimization.md)

---

## 💡 便利なコマンド集

- **デプロイ**: `sudo nixos-rebuild switch --flake .#BrokenPC`
- **秘密情報編集**: `sops secrets/secrets.yaml`
- **IPC 操作 (Noctalia)**: `noctalia-shell ipc call <target> <function>`
- **ビルド完了通知**: `curl -X POST ...` (詳細は `AGENTS.history.md` 参照)

---

> [!TIP]
> 作業ログを作成する際は、`2026-03-28-topic.md` のように日付を含めたファイル名にしてください。
