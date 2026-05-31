# NixOS 設定構築 - 運用・開発ガイド

このドキュメントは、本リポジトリの設計思想、開発ワークフロー、および作業履歴を管理するためのものです。

---

## 🚀 プロジェクト概要

本リポジトリは、宣言的で高度にカスタマイズされたデスクトップ環境及びサーバー群の構築を目指しています。

---

## 🛠️ 開発ワークフロー

### 1. 作業の基本ルール
- **ブランチ戦略**: 直接 `main` にコミットせず、`feature/<name>` または `refactor/<name>` ブランチを作成してください。
- **対応言語**: ユーザーへの報告、相談はすべて **日本語** で行います。
- **バイリンガル対応 (Bilingual Sync)**: プロジェクト内のドキュメント（ルートおよび各ディレクトリの `README.md` と `README.ja.md` 等）は、必ず**英語と日本語の両方を同時に同期して更新**してください。
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

## 📜 過去の履歴とログ
詳細は [作業ログのディレクトリ](./.agents/work-logs/) を参照してください。


---

## 💡 便利なコマンド集

- **デプロイ**: `sudo nixos-rebuild switch --flake .#BrokenPC`
- **torii-chan デプロイ (手動/SBC用)**: `nixos-rebuild switch --flake .#torii-chan --target-host t3u@10.0.0.1 --use-remote-sudo --ask-sudo-password --option sandbox false --option filter-syscalls false`
- **秘密情報編集**: `sops secrets/secrets.yaml`
- **IPC 操作 (Noctalia)**: `noctalia-shell ipc call <target> <function>`
- **ビルド完了通知**: `curl -X POST ...` (詳細は `AGENTS.history.md` 参照)

---

> [!TIP]
> 作業ログを作成する際は、`2026-03-28-topic.md` のように日付を含めたファイル名にしてください。
