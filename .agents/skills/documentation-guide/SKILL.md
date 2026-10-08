---
name: documentation-guide
description: このリポジトリにおけるドキュメントの執筆・構造化・保守に関するガイドライン．ドキュメントを作成・編集するときに必ず参照する．
---

# ドキュメント執筆・保守ガイドライン

このリポジトリにおけるドキュメント体系の整合性，鮮度，可読性を維持するための執筆・保守ルールである．

## 1. ドキュメント体系と責務分離

| 階層 / ディレクトリ | 言語 | 役割・責務 | 含まないもの（委ねる先） |
| :--- | :--- | :--- | :--- |
| **ルート** (`README.md`, `README.ja.md`) | 英 / 日 (同期) | リポジトリ概要，Tech Stack，全体構成，クイックスタート | 詳細な手順や各ホストの深掘り (`docs/`, `hosts/`) |
| **`docs/`** | 日本語 | **Single Source of Truth**．システム横断の設計仕様，運用手順，ハードウェア解説，障害復旧 | コードそのものの実装 |
| **各サブディレクトリ** (`hosts/*/`, `nixos/*/` 等) | 英語 | 当該ディレクトリのコード索引，モジュール一覧，ハードウェア諸元 | 長大な運用手順・システム横断の設計 (`docs/`) |
| **エージェント運用** (`AGENTS.md`, `GEMINI.md`, `TODO.md`) | 日本語 | エージェントの行動規範，ツール運用制約，実装進捗 | システムの詳細な技術仕様 (`docs/`) |
| **`.agents/skills/`** | 日 / 英 | エージェントが実行する作業手順・ノウハウ | システム全体の恒久的なドキュメント (`docs/`) |

---

## 2. 文体・スタイル規則

### 日本語文書 (`docs/`, `README.ja.md`, `AGENTS.md` 等)
- **句読点**: 必ず `，．` を使用する（全角の読点・句点はコミット時に pre-commit フックで `，．` に自動置換される）．
- **文体**: 技術文書として簡潔かつ論理的な常体（「〜である」「〜する」）を基本とする．
- **自然な日本語**: 機械翻訳調や不自然な主述関係，不必要な重複表現を排し，要点を明確に記述する．
- **箇条書き・表**: 視認性を重視し，比較や属性一覧はテーブル，手順は番号付きリストを活用する．
- **図解**: ネットワーク構成や処理フローは Mermaid ダイアグラムを活用する．

### 英語文書 (`README.md`, サブディレクトリ README)
- **文体**: 簡潔で客観的な技術英語（Imperative mood または叙述）．
- **過度な装飾の排除**: コードブロック，リスト，表を中心とし，冗長な説明文は削る．

---

## 3. 冗長性の排除と Single Source of Truth (SSOT)

1. **手順・仕様の重複禁止**:
   - 同一の手順（例: 新ホスト追加，SOPS 鍵登録，private flake input のブートストラップ等）を複数の README やスキルに重複して書かない．
   - 正本は `docs/operations/` 配下に配置し，他からはそこへのリンクを貼る．
2. **サブディレクトリ README のスリム化**:
   - 各コードディレクトリの README は，そのディレクトリ固有の仕様・オプション一覧・クイックコマンドに絞る．
   - ハードウェアの深いチューニングやトラブルシュートは `docs/hardware/` や `docs/troubleshooting/` に委ねる．

---

## 4. 相互参照（Cross-referencing）ルール

ドキュメント間およびコードとの相互参照を徹底し，読者やエージェントが迷わず関連情報へ到達できるようにする．

- **相対パスのリンク**:
  - `[ネットワーク設計](../../../docs/architecture/network-topology.md)` のように，相対パスでリンクを張る．
- **アンカーリンクの明記**:
  - 特定のセクションを参照する場合は，アンカーを正確に付与する．
- **関連ドキュメント節の設置**:
  - 各ドキュメントの末尾に `## 関連ドキュメント` または `## References` 節を設け，関連する `docs/`，コード，外部資料へのリンクをまとめる．

---

## 5. ドキュメントの配置マップ (`docs/`)

```text
docs/
├── README.md                          # 全体ナビゲーション・目次
├── architecture/                      # 設計仕様
│   ├── overview.md                    # リポジトリ層構成とモジュール評価フロー
│   ├── network-topology.md            # Nebula メッシュ, IP体系, DNS, ポートフォワード
│   └── flake-and-modules.md           # flake-parts, lib/mkSystem, my.* 命名規則
├── operations/                        # 運用ランブック
│   ├── adding-a-host.md               # 新ホスト追加・登録の統一手順 (SSOT)
│   ├── secret-management.md           # SOPS / age / 1Password 鍵ライフサイクル
│   ├── backup-and-restore.md          # Restic バックアップ運用, 障害時完全復旧 (DR) 手順
│   ├── vps-failover.md                # ConoHa VPS プロビジョニング & フェイルオーバー切替手順
│   └── maintenance.md                 # 日次自動更新, ガベージコレクション, カーネル更新
├── hardware/                          # ハードウェア・基盤別ガイド
│   ├── thinkpad-x1c7.md               # ThinkPad X1C7 固有設定
│   ├── hybrid-gpu.md                  # AMD+NVIDIA ハイブリッド, PRIME offload
│   ├── orange-pi-zero3.md             # Allwinner H618, U-Boot, SD/HDD ブート
│   └── storage-zfs.md                 # レガシー BIOS 構成, ZFS Mirror 保守
└── troubleshooting/                   # トラブルシューティング・FAQ
    ├── build-and-deploy.md            # ビルド・評価・キャッシュ・デプロイ失敗時
    ├── secrets-and-auth.md            # SOPS 復号エラー, private input 認証エラー
    ├── network-recovery.md            # Nebula 接続不能, NAT loopback, SSH 遮断復旧
    └── emergency-recovery.md          # ロールバック, インストーラ USB レスキュー
```
