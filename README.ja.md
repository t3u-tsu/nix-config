# NixOS 構成管理リポジトリ

このリポジトリは、NixOSのマルチホスト構成をFlakesを使用して管理しています。セキュリティ、再現性、およびクロスコンパイル環境を特徴としています。

## ℹ️ ドキュメントの構成

このリポジトリは階層構造になっており、詳細な説明は各所の `README.md` に記載されています。

- `hosts/<ホスト名>/`: 各マシンのハードウェア仕様と固有のデプロイ手順。
- `services/<サービス名>/`: 特定のサービス（Minecraft等）の詳細設定と運用方法。
- `common/`: 全ホストで共通して適用されるパッケージや設定。

## 📂 ディレクトリ構造

```text
.
├── flake.nix           # 構成のエントリポイント
├── hosts/              # ホスト固有の設定
├── common/             # 全ホスト共通の基本設定
├── services/           # 共通サービス（Minecraft, 等）の設定
│   └── minecraft/
│       └── plugins/    # nvfetcher によるプラグイン管理
├── lib/                # mkSystem などの共通ライブラリ関数
└── secrets/            # 暗号化された秘密情報 (SOPS)
```

## 🖥️ ホスト一覧 (Fleet)

| ホスト名 | 管理IP (WG0) | アプリIP (WG1) | 役割 | ストレージ |
| :--- | :--- | :--- | :--- | :--- |
| `torii-chan` | `10.0.0.1` | `10.0.1.1` | Gateway / DDNS (`mc.t3u.uk`) | SD + HDD |
| `sando-kun` | `10.0.0.2` | `10.0.1.2` | Sando Server | ZFS Mirror |
| `kagutsuchi-sama` | `10.0.0.3` | `10.0.1.3` | Compute / Minecraft Server | SSD + HDD |
| `shosoin-tan` | `10.0.0.4` | `10.0.1.4` | ZFS / Home Server | SSD + ZFS Mirror |

## 🛠️ 使用テクノロジー

- **Nix Flakes:** 再現可能なビルドと依存関係管理。
- **sops-nix:** `age` を使用した機密情報の暗号化管理。
- **nvfetcher:** 外部バイナリ（プラグイン等）の自動更新管理。
- **WireGuard:** 管理用(wg0)およびアプリ間通信用(wg1)のセキュアなネットワーク。
- **クロスコンパイル:** x86_64マシンでのaarch64 (ARM) ビルド。

---

## はじめかた

特定のホストやサービスについて詳しく知るには、それぞれのディレクトリにあるドキュメントを参照してください。
```bash
# 例: マシンの詳細を確認する
cat hosts/torii-chan/README.ja.md
```
