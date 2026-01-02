# ホスト名: kagutsuchi-sama (Xeon E5 計算サーバー)

このホストは、重い負荷の作業や計算タスクに使用される強力なタワー型サーバーです。

## ハードウェア仕様
- **CPU:** Xeon E5-2650 v2 (8コア/16スレッド)
- **GPU:** GTX 980 Ti (Maxwell)
- **RAM:** 16GB
- **ストレージ:**
  - 500GB SSD (ルート/ブート)
  - 3TB HDD (データ)
  - 160GB HDD (一時作業用)

## 🚀 インストールガイド

NixOS インストーラー環境から、外部マシン（BrokenPC）経由で以下のコマンドを実行します：

1. **ディスクの初期化とマウント:**
   ```bash
   ssh -t root@<ターゲットIP> "nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- \
     --mode destroy,format,mount \
     --flake github:t3u-tsu/nix-config#kagutsuchi-sama"
   ```

2. **SOPS 秘密鍵の配置:** (パスワード管理に必須)
   ```bash
   ssh root@<ターゲットIP> "mkdir -p /mnt/var/lib/sops-nix"
   cat ~/.config/sops/age/keys.txt | ssh root@<ターゲットIP> "cat > /mnt/var/lib/sops-nix/key.txt"
   ```

3. **NixOS のインストール:**
   ```bash
   ssh root@<ターゲットIP> "nixos-install --flake github:t3u-tsu/nix-config#kagutsuchi-sama"
   ```

4. **再起動:**
   ```bash
   ssh root@<ターゲットIP> "reboot"
   ```

## 🔐 アクセス
- **Update Producer:** ネットワーク全体の更新を主導する Producer。毎日 04:00 に `flake.lock` やプラグインを更新し、Git へのプッシュと Hub への通知を行います。
- **管理用IP:** `10.0.0.3` (WireGuard)
- **SSH アクセス制限:** セキュリティ強化のため、SSHアクセスは WireGuard (`wg0`) インターフェース経由のみに制限されています。
- **ユーザー:** `t3u` (wheel/sudo 権限あり)
- **パスワード:** `secrets.yaml` で定義 (sops-nix で管理)

管理用PCからのアクセス：
```bash
ssh t3u@10.0.0.3
```

## ⚠️ 注意事項: NAT ループバック問題
VPN サーバー (`torii-chan`) と同じ LAN 内にこのホストを設置する場合、ドメイン名 (`torii-chan.t3u.uk`) による VPN 接続がルーターの制限（NAT ループバック非対応）により失敗することがあります。

### 対策
`configuration.nix` で `my.localNetwork.enable = true;` を設定しています。これにより、`torii-chan.t3u.uk` が自動的にローカル IP (`192.168.0.128`) に解決されます。

**外部ネットワークへ移動する場合:**
このホストを別のネットワークへ移動させる際は、`my.localNetwork.enable = false;` に変更して `nixos-rebuild switch` を実行してください。そうしないと、外部から VPN サーバーを見つけることができなくなります。

