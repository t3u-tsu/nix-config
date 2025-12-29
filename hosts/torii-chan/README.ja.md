# ホスト名: torii-chan (Orange Pi Zero3)

このディレクトリには、WireGuardサーバーおよびDDNSクライアントとして使用される `torii-chan` (Orange Pi Zero3) のNixOS設定が含まれています。

## ハードウェア仕様
- **モデル:** Orange Pi Zero3 (Allwinner H618)
- **アーキテクチャ:** aarch64-linux

## Flake内の構成
- `torii-chan-sd`: 初期セットアップ用SDイメージのビルド。
- `torii-chan-sd-live`: SDカード運用での設定更新。
- `torii-chan`: HDDルート運用向けの本番構成。

---

## 🚀 セットアップガイド

### Phase 1: SDイメージのビルドと書き込み
1. **ビルド:**
   ```bash
   nix build .#nixosConfigurations.torii-chan-sd.config.system.build.sdImage
   ```
2. **書き込み:**
   ```bash
   sudo dd if=result/sd-image/nixos-image-sd-card-*.img of=/dev/sdX bs=4M status=progress conv=fsync
   ```

### Phase 2: 初期プロビジョニング
1. **鍵の配置:** age秘密鍵を `/var/lib/sops-nix/key.txt` に配置します。
2. **初回デプロイ:**
   ```bash
   nix run nixpkgs#nixos-rebuild -- switch --flake .#torii-chan-sd-live --target-host root@192.168.0.128
   ```

### Phase 3: HDD移行 (オプション)
1. **HDD準備:** ラベル `NIXOS_HDD` でフォーマットします。
2. **データコピー:** `/` をHDDパーティションにrsyncします。
3. **構成切り替え:**
   ```bash
   nix run nixpkgs#nixos-rebuild -- switch --flake .#torii-chan --target-host t3u@10.0.0.1 --use-remote-sudo
   ```

## 🔐 サービスと秘密情報
- **WireGuard:** ポート51820のVPNサーバー。
- **DDNS:** Cloudflare DDNS (favonia)。APIトークンが必要です。
- **秘密情報:** `sops-nix` で管理。 `sops secrets/secrets.yaml` で編集。
