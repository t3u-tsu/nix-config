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
- **ユーザー:** `t3u` (wheel/sudo 権限あり)
- **パスワード:** `secrets.yaml` で定義 (sops-nix で管理)
- **SSH 鍵:** `t3u` および `root` ユーザーで有効

