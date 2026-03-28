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
- **対応言語**: ユーザーへの報告、相談はすべて **日本語** で行います。
- **バイリンガル対応 (Bilingual Sync)**: プロジェクト内のドキュメント（ルートおよび各ホストの `README.md` と `README.ja.md` 等）は、必ず**英語と日本語の両方を同時に同期して更新**してください。
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

- **2026-03-29 (SOPS Decryption Fix)**: `.sops.yaml` への鍵追加に伴う手動復号不全の問題を解消。`ssh-to-age` をパッケージに追加し、`sops-nix` の SSH 鍵統合を修正するとともに、ユーザ用 `sops` エイリアスを導入。
- **2026-03-28 (Phase 9 CI/CD integration)**: 旧 `update-hub` を完全に廃止し、`GitHub Actions` による自動更新 (`nvfetcher`) と `comin` による自動デプロイを統合。タワーサーバーの記述ミスを修正し、監視基盤との整合性を確保。
- **2026-03-28 (Phase 8.5 Deploy Fixes)**: `torii-chan` 実機環境での Nix サンドボックス非互換エラーの回避、`production-security.nix` の `lib.mkForce` ファイアウォール競合の解決。およびプロジェクト全体を通した英語・日本語ドキュメントの全面同期（WezTerm移行の反映など）。
- **2026-03-28 (Phase 8-8.5)**: WezTerm移行、Steam Millennium導入、Wayland UIの競合解決。Prometheus+Grafanaによる艦隊監視ダッシュボード基盤の構築とCI/CD導入。
- **2026-03-28 (Phase 7)**: UI 移行 (Nautilus -> Thunar) と自動デプロイ基盤の刷新 (comin 導入)、CI/CD 準備。
- **2026-03-28 (Phase 5-6)**: Noctalia UI 最適化、NVIDIA ドライバの抽象化、システムパッケージ再整理。
- **2026-03-27**: Noctalia Shell 構成の高度化、Spotify テーマ適用。
- **2026-03-10**: Niri への完全移行実施、greetd 導入。

---

## 📜 過去の履歴とログ
詳細は [作業ログのディレクトリ](./.agents/work-logs/) を参照してください。

### 各セッションの詳細ログ（抜粋）
- [2026-03-29: SOPS 権限・復号問題の解決](./.agents/work-logs/2026-03-29-sops-decryption-fix.md)
- [2026-03-28: CI/CD 統合 & 監視基盤最適化 Phase 9](./.agents/work-logs/2026-03-28-ci-cd-optimization.md)
- [2026-03-28: torii-chan デプロイ障害とファイアウォール競合の解決](./.agents/work-logs/2026-03-28-torii-chan-deployment-fixes.md)
- [2026-03-28: デスクトップ最適化 & 監視基盤配備 Phase 8-8.5](./.agents/work-logs/2026-03-28-phase8-desktop-monitoring.md)
- [2026-03-28: デスクトップ最適化 & インフラ刷新 Phase 7](./.agents/work-logs/2026-03-28-phase7-infrastructure.md)
- [2026-03-28: デスクトップ最適化 Phase 2 & クリーンアップ](./.agents/work-logs/2026-03-28-desktop-fixes-v2.md)
- [2026-03-27: デスクトップ最適化 Phase 1](./.agents/work-logs/2026-03-27-desktop-optimization.md)

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
