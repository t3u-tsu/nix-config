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

NixOS インストーラー環境から以下のコマンドを実行します：

1. **ディスクの初期化とマウント:**
   ```bash
   sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- \
     --mode destroy,format,mount \
     --flake github:t3u-tsu/nix-config#kagutsuchi-sama
   ```

2. **NixOS のインストール:**
   ```bash
   sudo nixos-install --flake github:t3u-tsu/nix-config#kagutsuchi-sama
   ```

3. **t3u ユーザーのパスワード設定:**
   再起動後、`configuration.nix` で定義された SSH 公開鍵を使用して `t3u` ユーザーでログインできます。
