# NixOS 構成管理リポジトリ

このリポジトリは、NixOSのマルチホスト構成をFlakesを使用して管理しています。クロスコンパイルや安全な秘密情報管理を特徴としています。

## ディレクトリ構造

```text
.
├── flake.nix           # 構成のエントリポイント
├── hosts/              # ホスト固有の設定
│   └── torii-chan/     # Orange Pi Zero3 の設定
├── lib/                # mkSystem などの共通ライブラリ関数
├── secrets/            # 暗号化された秘密情報 (SOPS)
│   └── secrets.yaml
└── temp/               # ドキュメントや参考資料
```

## ホスト一覧

| ホスト名 | ハードウェア | プラットフォーム | 役割 | ドキュメント |
| :--- | :--- | :--- | :--- | :--- |
| `torii-chan` | Orange Pi Zero3 | aarch64-linux | WireGuard / DDNS | [README](hosts/torii-chan/README.ja.md) |

## 使用テクノロジー

- **Flakes:** 再現可能なビルドと依存関係管理。
- **sops-nix:** `age` を使用した機密情報の暗号化管理。
- **クロスコンパイル:** x86_64マシンでのaarch64 (ARM) ビルド。

## はじめかた

特定のホストについて詳しく知るには、`hosts/` 配下の各ディレクトリにあるREADMEを参照してください。