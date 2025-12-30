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

| ホスト名 | 管理IP (WG) | 役割 | ハードウェア詳細 | ストレージ |
| :--- | :--- | :--- | :--- | :--- |
| `torii-chan` | `10.0.0.1` | Gateway / WG Server | Orange Pi Zero3 (H618 / 1GB) | 64GB SD / 500GB HDD |
| `shosoin-tan` | `10.0.0.4` | ZFS / Home Server | i7 870 / 16GB / K2200 | 480GB SSD / ZFS Mirror |
| `kagutsuchi-sama` | `10.0.0.3` | Compute Server | Xeon E5-2650 v2 / 16GB / GTX 980 Ti | 500GB SSD / 3TB HDD |
| `sando-kun` | `10.0.0.2` | (Reserved) | - | - |

## セキュリティ構成

- **管理用ネットワーク:** WireGuardによる `10.0.0.0/24` のプライベートネットワークを構築。
- **SSH 制限:** セキュリティ強化のため、**SSHアクセスは WireGuard (`wg0`) インターフェース経由のみ**に制限されています。LAN側（192.168.x.x）からのアクセスは遮断されます。
- **秘密情報管理:** `sops-nix` と `age` を使用し、パスワードやAPIキーを暗号化して管理しています。

## 使用テクノロジー

- **Flakes:** 再現可能なビルドと依存関係管理。
- **sops-nix:** `age` を使用した機密情報の暗号化管理。
- **クロスコンパイル:** x86_64マシンでのaarch64 (ARM) ビルド。

## デプロイガイド

### x86_64 ホスト (kagutsuchi-sama, shosoin-tan)

NixOS ライブUSBを使用して新規マシンにデプロイする手順：

1. **ターゲットマシンをライブUSBから起動。**
2. **ターゲット側で SSH をセットアップ:** (アクセスできない場合のみ)
   ```bash
   sudo passwd root # 一時的なパスワードを設定
   ```
3. **Disko によるパーティショニング (ローカルマシンから実行):**
   ```bash
   ssh -t root@<ターゲットIP> "nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- \
     --mode destroy,format,mount \
     --flake github:t3u-tsu/nix-config#<ホスト名>"
   ```
4. **NixOS のインストール (ローカルマシンから実行):**
   ```bash
   ssh root@<ターゲットIP> "nixos-install --flake github:t3u-tsu/nix-config#<ホスト名>"
   ```
5. **再起動:**
   ```bash
   ssh root@<ターゲットIP> "reboot"
   ```

---

## はじめかた

特定のホストについて詳しく知るには、`hosts/` 配下の各ディレクトリにあるREADMEを参照してください。
