# NixOS設定構築のコンテキスト

## 目的

`.` ディレクトリにて、Orange Pi Zero3 (`torii-chan`) 向けのNixOS設定を構築中。最終目標はSDカードイメージの生成と実機へのデプロイです。

## 現在の状況 (2025-12-29)

**Disko廃止・標準SDイメージへの移行完了。U-Boot定義を追加。**

### 達成したマイルストーン

1.  **SDイメージ生成の軽量化:**
    - `disko` を廃止し、NixOS標準の `sd-image-aarch64.nix` モジュールに切り替え。
    - `hosts/torii-chan/sd-image-installer.nix` を作成し、U-Boot (`u-boot-sunxi-with-spl.bin`) を書き込む構成に変更。
    - 無限再帰の原因となっていた `qemu` のオーバーレイを削除。
2.  **構成の分離:**
    - `flake.nix` にて、SD作成用 (`torii-chan-sd`) と実運用用 (`torii-chan`) の2つのターゲットを定義。
    - `nix flake check` による構文・依存関係チェックが正常に通過することを確認済み。
3.  **U-Boot 定義の実装:**
    - `flake.nix` の `overlays` に `ubootOrangePiZero3` を定義 (`defconfig = "orangepi_zero3_defconfig"`).
    - ソースは `u-boot/u-boot` (v2024.01) を指定（ハッシュは仮置き）。

### 直面している課題

1.  **U-Boot ソースハッシュの修正:**
    - `flake.nix` に記述した U-Boot の `sha256` は仮の値のため、初回のビルド時に正しいハッシュを取得して書き換える必要がある。

### リポジトリ構造 (最新)

- `.`:
    - `flake.nix`: `torii-chan-sd` (SD用) と `torii-chan` (将来のSSD用) を定義。U-Boot Overlay追加。
    - `hosts/torii-chan/`:
        - `configuration.nix`: 共通設定。Disko削除。
        - `sd-image-installer.nix`: SDイメージ生成とU-Boot書き込み定義。
        - `disko.nix`: (未使用)

## 次のステップ（再開後すぐ）

1.  **ハッシュの特定と修正:**
    - `nix build .#nixosConfigurations.torii-chan-sd.config.system.build.sdImage` を実行し、ハッシュ不一致エラーを出させる。
    - エラーメッセージに出た正しいハッシュを `flake.nix` に適用する。
2.  **ビルド完遂:**
    - 再度ビルドを実行し、`result/sd-image/` にイメージが生成されることを確認する。

## デプロイ手順

1.  `nix build .#nixosConfigurations.torii-chan-sd.config.system.build.sdImage`
2.  SDカード書き込み -> 実機起動。
