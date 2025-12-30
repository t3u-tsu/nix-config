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
    └── secrets.yaml
```

## ホスト一覧

| ホスト名 | ハードウェア詳細 | プラットフォーム | 役割 | ドキュメント |
| :--- | :--- | :--- | :--- | :--- |
| `torii-chan` | Orange Pi Zero3 (H618 / 1GB RAM / 500GB HDD) | aarch64-linux | WireGuard / DDNS | [README](hosts/torii-chan/README.ja.md) |
| `shosoin-tan` | Core i7 870 / 16GB RAM / K2200 / ZFS | x86_64-linux | ZFS Server | [README](hosts/shosoin-tan/README.ja.md) |
| `kagutsuchi-sama` | Xeon E5-2650 v2 / 16GB RAM / GTX 980 Ti | x86_64-linux | Compute Server | - |

### 詳細スペック

#### torii-chan
- **CPU:** Allwinner H618
- **RAM:** 1GB
- **ストレージ:** 64GB microSD (Boot), 500GB HDD (Root)

#### shosoin-tan
- **CPU:** Core i7 870
- **GPU:** Quadro K2200
- **RAM:** 16GB
- **ストレージ:** 480GB SSD (Root), 1TB x2 + 320GB x2 (ZFS), 2TB HDD (Backup)

#### kagutsuchi-sama
- **CPU:** Xeon E5-2650 v2
- **GPU:** GTX 980 Ti (Maxwell)
- **RAM:** 16GB
- **ストレージ:** 500GB SSD (Root), 3TB + 160GB HDD

## 使用テクノロジー

- **Flakes:** 再現可能なビルドと依存関係管理。
- **sops-nix:** `age` を使用した機密情報の暗号化管理。
- **クロスコンパイル:** x86_64マシンでのaarch64 (ARM) ビルド。

## デプロイガイド

### x86_64 ホスト (kagutsuchi-sama, shosoin-tan)

`nixos-anywhere` 等の自動ツールが失敗する場合、インストーラー環境から以下の手動手順を実行します：

1. **Disko によるパーティショニングとマウント:**
   ターゲットマシン上（または SSH 経由）で実行します：
   ```bash
   sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- \
     --mode destroy,format,mount \
     --flake github:t3u-tsu/nix-config#<ホスト名>
   ```

2. **NixOS のインストール:**
   ```bash
   sudo nixos-install --flake github:t3u-tsu/nix-config#<ホスト名>
   ```

3. **再起動:**
   ```bash
   sudo reboot
   ```

---

## はじめかた

特定のホストについて詳しく知るには、`hosts/` 配下の各ディレクトリにあるREADMEを参照してください。
