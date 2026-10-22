# NixOS 設定リポジトリ 設計・運用ドキュメント

システム全体のアーキテクチャ設計仕様，運用手順書，ハードウェア固有ガイド，およびトラブルシューティング情報．

## ドキュメント一覧

### 1. [アーキテクチャ設計](architecture/)
- [architecture/overview.md](architecture/overview.md) — リポジトリの層構成とモジュール評価フロー
- [architecture/network-topology.md](architecture/network-topology.md) — Nebula メッシュネットワーク，IP 体系，ポートフォワード，DNS 設計
- [architecture/flake-and-modules.md](architecture/flake-and-modules.md) — Flake 構成，`mkSystem`, `my.*` オプション設計原則

### 2. [運用手順書](operations/)
- [operations/adding-a-host.md](operations/adding-a-host.md) — 新規マシンの追加・初期セットアップの標準手順
- [operations/secret-management.md](operations/secret-management.md) — SOPS / age / 1Password 鍵ライフサイクル，証明書更新
- [operations/backup-and-restore.md](operations/backup-and-restore.md) — Restic バックアップ運用，障害時完全復旧 (DR) 手順
- [operations/vps-failover.md](operations/vps-failover.md) — ConoHa VPS プロビジョニング & フェイルオーバー切替・切戻し手順
- [operations/emergency-cf-ssh.md](operations/emergency-cf-ssh.md) — Cloudflare Tunnel を用いた非常用 SSH アクセス手順 (帯域外管理)
- [operations/maintenance.md](operations/maintenance.md) — 日次自動更新，ガベージコレクション，定期保守

### 3. [ハードウェア固有ガイド](hardware/)
- [hardware/thinkpad-x1c7.md](hardware/thinkpad-x1c7.md) — ThinkPad X1C7: 電源管理，指紋認証，オーディオワークアラウンド
- [hardware/hybrid-gpu.md](hardware/hybrid-gpu.md) — BrokenPC: AMD + 故障 NVIDIA ハイブリッド GPU 分離，CUDA/LLM オフロード
- [hardware/orange-pi-zero3.md](hardware/orange-pi-zero3.md) — torii-chan: Allwinner H618 SBC, U-Boot，低スペック制約
- [hardware/storage-zfs.md](hardware/storage-zfs.md) — shosoin-tan / sando-kun: レガシー BIOS ブート，ZFS Mirror 保守・リビルド

### 4. [トラブルシューティング](troubleshooting/)
- [troubleshooting/build-and-deploy.md](troubleshooting/build-and-deploy.md) — ビルド・評価・キャッシュ・デプロイ失敗時
- [troubleshooting/secrets-and-auth.md](troubleshooting/secrets-and-auth.md) — SOPS 復号エラー，private input 認証エラー
- [troubleshooting/network-recovery.md](troubleshooting/network-recovery.md) — Nebula 不通，NAT loopback，SSH 遮断時の復旧
- [troubleshooting/emergency-recovery.md](troubleshooting/emergency-recovery.md) — 世代ロールバック，インストーラ USB レスキュー

### 5. [調査ノート](research/)
認証スタックなど，実機調査と upstream ソースコードの読解に基づく調査記録．
- [research/parallel-auth-architecture.md](research/parallel-auth-architecture.md) — 指紋 + パスワード並行待ち受けの可否と，GDM / Noctalia / greetd / polkit / sudo の実装比較
- [research/parallel-auth-upstream-history.md](research/parallel-auth-upstream-history.md) — 各 upstream における並行認証の歴史と挫折理由 (Linux-PAM, SDDM, COSMIC, hyprlock 等)
- [research/greetd-parallel-design.md](research/greetd-parallel-design.md) — greetd 互換並行認証デーモン (greetd-parallel) の設計・自己実装仕様
- [research/bsd-auth-architecture.md](research/bsd-auth-architecture.md) — FreeBSD / NetBSD (OpenPAM) と OpenBSD (BSD Authentication) の同期性・並行性
- [research/fprintd-triage-notes.md](research/fprintd-triage-notes.md) — x1c7 実機での fprintd トリアージ記録 (PAM 順序，D-Bus 自動終了，Noctalia の Claim 挙動)

---

## 関連ドキュメント
- [ルート概要](../README.md) — リポジトリ全体の構成とクイックスタート
- [日本語概要](../README.ja.md) — 日本語版リポジトリ概要
- [エージェント行動規範](../AGENTS.md) — 全作業エージェント共通の運用ガイド
- [執筆・保守ガイド](../.agents/skills/documentation-guide/SKILL.md) — ドキュメントの執筆・構造化ガイドライン
- [タスク台帳](../TODO.md) — リポジトリの未完了タスク・ロードマップ
