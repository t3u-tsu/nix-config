# ホスト名: sando-kun (i7-860 タワーサーバー)

このホストは、Core i7-860 と 80GB HDD x2 の ZFS Mirror 構成を備えた、汎用タワー型サーバーです。`shosoin-tan` や `kagutsuchi-sama` と同様の標準構成を採用しています。

## ハードウェア仕様
- **CPU:** Intel Core i7-860 (第一世代)
- **GPU:** GeForce 8400 GS (Tesla)
- **RAM:** 8GB
- **ストレージ:**
  - 250GB HDD (OS / Boot)
  - 80GB HDD (`scratch`)

## 🚀 インストールガイド

このホストは古いハードウェアのため、負荷軽減と互換性のために以下の手順（shosoin-tan と同様）でインストールを行います。

### Phase 1: ディスクの準備
1. **Disko の実行:** 別のマシンから以下の手順で実行。
   ```bash
   nix build .#nixosConfigurations.sando-kun.config.system.build.diskoScript
   nix copy --to ssh://nixos@<IP> ./result
   ssh -t nixos@<IP> "sudo ./result --mode destroy,format,mount"
   ```

### Phase 2: 秘密鍵の転送
```bash
ssh nixos@<IP> "sudo mkdir -p /mnt/var/lib/sops-nix"
cat ~/.config/sops/age/keys.txt | ssh nixos@<IP> "sudo tee /mnt/var/lib/sops-nix/key.txt > /dev/null"
```

### Phase 3: システムのビルドと転送（推奨）
本体の CPU 負荷を抑えるため、ビルドホストで作成したイメージを転送します。
1. **ビルド:** `nix build .#nixosConfigurations.sando-kun.config.system.build.toplevel`
2. **転送:** `nix copy --to ssh://nixos@<IP> ./result`
3. **インストール:** `ssh nixos@<IP> "sudo nixos-install --system $(readlink -f ./result)"`

## 🔐 ネットワークとセキュリティ
- **ブート方式:** Legacy BIOS (MBR)
- **Update Consumer:** `shosoin-tan` からの通知を受けて自動更新を適用します。
- **ZFS:** `/mnt/tank-80gb` が自動的にマウントされます。
- **管理用IP:** `10.0.0.2` (WireGuard)
- **アプリ用IP:** `10.0.1.2`
- **SSH アクセス制限:** セキュリティ強化のため、SSHアクセスは WireGuard (`wg0`) インターフェース経由のみに制限。

## ⚠️ 注意事項
- **GPU:** GeForce 8400 GS は非常に古いため、現代の NVIDIA ドライバは動作しません。オープンソースの `nouveau` ドライバまたは標準のカーネルドライバで動作します。
- **ZFS インポート:** 初回起動時にプールが見つからない場合は、`sudo zpool import -f tank-80gb` で強制インポートを試みてください。
