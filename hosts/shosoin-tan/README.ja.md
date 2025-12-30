# shosoin-tan (タワー型サーバー)

ZFSストレージとNVIDIA Quadroを搭載した汎用サーバー。

## ハードウェア仕様
- **CPU**: Intel Core i7 870
- **GPU**: NVIDIA Quadro K2200
- **ストレージ**:
  - 480GB SSD: ルート領域 (`/`)
  - 1TB HDD x2: ZFSミラー (`tank-1tb`)
  - 320GB HDD x2: ZFSミラー (`tank-320gb`)
  - 2TB HDD: バックアップ用領域 (`ext4`)

## 初期セットアップ
1. NixOSインストーラーで起動。
2. `disko` を実行してディスクのパーティション作成とフォーマットを行う。
3. `nixos-install --flake .#shosoin-tan` でインストールを実行。
