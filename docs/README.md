# NixOS 設定リポジトリ 設計・運用ドキュメント

このディレクトリは，本リポジトリで管理されているシステム全体のアーキテクチャ設計，運用ランブック，ハードウェア固有ガイド，トラブルシューティング情報を一元管理する **Single Source of Truth (SSOT)** である．

## 目次と構成

### 1. [アーキテクチャ設計 (Architecture)](architecture/)
システム全体の基本構造，評価フロー，ネットワークトポロジに関する設計仕様書．
- [`architecture/overview.md`](architecture/overview.md) — リポジトリの層構成とモジュール評価フロー
- [`architecture/network-topology.md`](architecture/network-topology.md) — Nebula メッシュネットワーク，IP 体系，ポートフォワード，DNS 設計
- [`architecture/flake-and-modules.md`](architecture/flake-and-modules.md) — Flake 構成，`mkSystem`，`my.*` オプション設計原則

### 2. [運用ランブック (Operations)](operations/)
日常の保守運用および非常時の対応手順書．
- [`operations/adding-a-host.md`](operations/adding-a-host.md) — 新規マシンの追加・初期セットアップ手順 (SSOT)
- [`operations/secret-management.md`](operations/secret-management.md) — SOPS / age / 1Password 鍵ライフサイクル，年次証明書更新
- [`operations/backup-and-restore.md`](operations/backup-and-restore.md) — Restic バックアップ運用，障害時完全復旧 (DR) 手順
- [`operations/vps-failover.md`](operations/vps-failover.md) — ConoHa VPS プロビジョニング & フェイルオーバー切替・切戻し手順
- [`operations/maintenance.md`](operations/maintenance.md) — 日次自動更新，ガベージコレクション，定期保守

### 3. [ハードウェア固有ガイド (Hardware)](hardware/)
各マシンの固有ハードウェア特性，チューニング，制約事項の解説．
- [`hardware/thinkpad-x1c7.md`](hardware/thinkpad-x1c7.md) — ThinkPad X1C7: 電源管理，指紋認証，オーディオワークアラウンド
- [`hardware/hybrid-gpu.md`](hardware/hybrid-gpu.md) — BrokenPC: AMD + 故障 NVIDIA ハイブリッド GPU 分離，CUDA/LLM オフロード
- [`hardware/orange-pi-zero3.md`](hardware/orange-pi-zero3.md) — torii-chan: Allwinner H618 SBC，U-Boot，低スペック制約
- [`hardware/storage-zfs.md`](hardware/storage-zfs.md) — shosoin-tan / sando-kun: レガシー BIOS ブート，ZFS Mirror 保守・リビルド

### 4. [トラブルシューティング (Troubleshooting)](troubleshooting/)
頻出エラーの原因と復旧手順．
- [`troubleshooting/build-and-deploy.md`](troubleshooting/build-and-deploy.md) — ビルド・評価・キャッシュ・デプロイ失敗時
- [`troubleshooting/secrets-and-auth.md`](troubleshooting/secrets-and-auth.md) — SOPS 復号エラー，private input 認証エラー
- [`troubleshooting/network-recovery.md`](troubleshooting/network-recovery.md) — Nebula 不通，NAT loopback，SSH 遮断時の復旧
- [`troubleshooting/emergency-recovery.md`](troubleshooting/emergency-recovery.md) — 世代ロールバック，インストーラ USB レスキュー

---

## 関連リファレンス
- ルート概要: [`../README.md`](../README.md) / [`../README.ja.md`](../README.ja.md)
- エージェント作業ルール: [`../AGENTS.md`](../AGENTS.md)
- ドキュメント執筆・保守ガイド: [`../.agents/skills/documentation-guide/SKILL.md`](../.agents/skills/documentation-guide/SKILL.md)
- 未完了タスク一覧: [`../TODO.md`](../TODO.md)
