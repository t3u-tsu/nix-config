# NixOS設定構築のコンテキスト

## 目的

`.` ディレクトリにて、Orange Pi Zero3 (`torii-chan`) 向けのNixOS設定を構築中。最終目標はSDカードイメージの生成と実機へのデプロイです。

## 現在の状況 (2025-12-29)

**SDイメージのビルドに成功。U-Bootのハッシュ不一致とATF（BL31）の欠落を解消。**

### 達成したマイルストーン

1.  **SDイメージ生成の成功:**
    - `nix build` が正常に完了し、`result/sd-image/` にイメージが生成された。
2.  **U-Boot 定義の完成:**
    - 正しいソースハッシュ（`sha256-0Da7Czy9cpQ+D5EICc3/QSZhAdCBsmeMvBgykYhAQFw=`）を特定。
    - `armTrustedFirmwareAllwinnerH616` を `BL31` として追加し、`binman` によるイメージ生成エラーを解消。
3.  **構成の整理:**
    - `disko` 廃止、標準モジュールへの移行、Gitブランチの `main` 変更などが全て完了。

### 直面している課題
(現在、大きなビルドエラーはなし)

### リポジトリ構造 (最新)
(変更なし)

## 次のステップ

1.  **実機デプロイ:**
    - 生成されたイメージをSDカードに書き込み、Orange Pi Zero 3 での起動を確認する。
2.  **SSD運用向けの設定実装:**
    - SDカードでの起動が確認でき次第、将来的なSSD (NVMe/SATA) 運用に向けたファイルシステム設定 (`fs-ssd.nix` 等) を `hosts/torii-chan` に追加する。
3.  **秘密情報の管理:**
    - SOPS-NIX が正しく機能するか、実機上で確認する（`/var/lib/sops-nix/key.txt` の配置など）。

## デプロイ手順

1.  `nix build .#nixosConfigurations.torii-chan-sd.config.system.build.sdImage --impure --extra-experimental-features 'nix-command flakes'`
2.  SDカード書き込み: `sudo dd if=result/sd-image/nixos-image-sd-card-...-aarch64-linux.img of=/dev/sdX bs=4M status=progress conv=fsync`
3.  実機起動。

## デプロイ手順

1.  `nix build .#nixosConfigurations.torii-chan-sd.config.system.build.sdImage`
2.  SDカード書き込み -> 実機起動。
