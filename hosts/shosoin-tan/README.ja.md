# ホスト名: shosoin-tan (i7-870 タワーサーバー)

このホストは、Core i7-870 と ZFS Mirror 構成を備えた、Minecraft サーバー兼データ保存・汎用サービスのためのタワー型サーバーです。

## ハードウェア仕様
- **CPU:** Intel Core i7-870 (第一世代)
- **GPU:** Quadro K2200 (Maxwell)
- **RAM:** 16GB
- **ストレージ:**
  - 480GB SSD (OS / Boot)
  - 1TB HDD x2 (ZFS Mirror: `tank-1tb`)
  - 320GB HDD x2 (ZFS Mirror: `tank-320gb`)

## 🚀 インストールガイド

このホストは古いハードウェアのため、負荷軽減と互換性のために以下の特殊な手順でインストールを行いました。

### Phase 1: ディスクの準備
1. **Disko の実行:** 別の Linux マシンから以下の手順で実行。
   ```bash
   nix build .#nixosConfigurations.shosoin-tan.config.system.build.diskoScript
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
1. **ビルド:** `nix build .#nixosConfigurations.shosoin-tan.config.system.build.toplevel`
2. **転送:** `nix copy --to ssh://nixos@<IP> ./result`
3. **インストール:** `ssh nixos@<IP> "sudo nixos-install --system $(readlink -f ./result)"`

## 🔐 ネットワークとセキュリティ
- **ブート方式:** Legacy BIOS (MBR)
- **Update Producer:** ネットワーク全体の更新を主導する Producer。毎日 04:00 に `flake.lock` やプラグインを更新し、Git へのプッシュと Hub への通知を行います。
- **Minecraft データ:** `/srv/minecraft` に配置。
- **Minecraft Discord Bridge:** Discord からの管理用 Bot が稼働中。ソケットは `/run/minecraft-discord-bridge/bridge.sock`。
- **バックアップ:** 2時間おきに `restic` で実行。
  - ローカル (`/mnt/tank-1tb/backups/minecraft`) とリモート (`kagutsuchi-sama`) の2重構成。
- **管理用IP:** `10.0.0.4` (WireGuard)
- **アプリ用IP:** `10.0.1.4` (Minecraft 等)
- **MTU設定:** USB-LAN 変換アダプタ使用時の安定性向上のため、WireGuard の MTU を `1380` に設定しています。
- **SSH アクセス制限:** セキュリティ強化のため、SSHアクセスは WireGuard (`wg0`) インターフェース経由のみに制限。

## ⚠️ 注意事項
- **オーバークロック:** CPU のオーバークロックは Nix の高負荷ビルド時に不安定（Kernel Oops）を誘発するため、原則として定格運用を推奨。
- **resolv.conf:** インストール直後に `resolv.conf` の署名不一致でネットワークサービスが落ちる場合は、`/etc/resolv.conf` 手動削除して再起動すること。
