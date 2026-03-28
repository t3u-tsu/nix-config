# 2026-03-28: CI/CD 統合と update-hub 廃止に伴うワークフロー最適化

## 概要 / Overview
旧式の自作更新管理システム `update-hub` を完全に廃止し、`GitHub Actions` と `comin` を組み合わせたモダンな CI/CD ワークフローへ移行しました。また、共通プロファイルのバグ修正により、全タワーサーバーのデプロイ機能を復旧しました。

Abolished the legacy `update-hub` system and migrated to a modern CI/CD workflow combining `GitHub Actions` and `comin`. Fixed a syntax error in the common profile to restore deployment functionality for all tower servers.

## 実施内容 / Changes Made

### 1. 更新ワークフローの刷新 / Revamped Update Workflow
- **GitHub Actions (`auto-update.yml`)**: `nvfetcher` と `nix flake update` を CI 上で自動実行し、リポジトリを更新する「Producer」機能を実装。
- **comin**: 各ホストが CI 側のプッシュを検知して自動デプロイする「Consumer」として構成を統一。
- **メリット**: ローカルホストへの依存（特定の Producer マシンが不要）と、トークン管理の安全性が向上。

### 2. 不具合修正 / Bug Fixes
- **Tower Server Profile**: `modules/profiles/tower-server/default.nix` における `lib` 変数の未定義エラーを修正。これにより、`shosoin-tan`, `kagutsuchi-sama`, `sando-kun` の自動デプロイが正常化。
- **Firewall クリーンアップ**: `torii-chan` のセキュリティ設定から不要となったポート 8080 の開放設定を削除。

### 3. クリーンアップ / Cleanup
- `modules/services/update-hub/` ディレクトリを完全に物理削除。
- `modules/services/minecraft` 等、各所から旧システムのオプション残骸を一掃。

## 検証結果 / Verification Results
- `nix flake check`: パス。
- 各ホストの評価テスト (`BrokenPC`, `shosoin-tan`): 正常に完了。
- `comin` 稼働状況: 各ホストでの動作と、WireGuard 経由の SSH 疎通を確認済み。

## 今後の展望 / Future Tasks
- `TODO.md` にある「艦隊ダッシュボード」の作成（`comin` 連携）への着手。
