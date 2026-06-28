# nix-config

[![Nix Flake Check](https://github.com/t3u-tsu/nix-config/actions/workflows/nix-check.yml/badge.svg)](https://github.com/t3u-tsu/nix-config/actions/workflows/nix-check.yml)
![NixOS](https://img.shields.io/badge/NixOS-26.05-blue.svg?logo=NixOS&logoColor=white)
![Nix Flakes](https://img.shields.io/badge/Nix%20Flakes-Enabled-blueviolet.svg?logo=NixOS&logoColor=white)
[![License](https://img.shields.io/github/license/t3u-tsu/nix-config)](https://github.com/t3u-tsu/nix-config/blob/main/LICENSE)

[English](README.md)

Flakes を用いてデスクトップやサーバー群の設定を一元管理しています．

## ディレクトリ構造

```text
.
├── flake.nix        # システム全体のエントリポイント
├── hosts/           # ホスト固有の設定 (BrokenPC, torii-chan, etc.)
└── modules/         # 再利用可能なモジュール集
    ├── core/        # 基本システム設定 (Nix, ネットワーク, SOPS)
    ├── hardware/    # ハードウェア固有設定 (NVIDIA, udev 等)
    ├── home/        # ユーザー環境設定 (Home Manager)
    ├── packages/    # システムパッケージグループの定義
    ├── profiles/    # 役割別のホストプロファイル
    └── services/    # 特殊なサービス設定 (バックアップ, Minecraft 等)
```

## クイックスタート

ローカルマシンの設定を適用する場合：

```bash
sudo nixos-rebuild switch --flake .#<hostname>
```

リモートマシン（例: Orange Pi Zero 3 の `torii-chan`）へデプロイする場合：

```bash
nixos-rebuild switch --flake .#torii-chan --target-host t3u@10.0.0.1 --use-remote-sudo --ask-sudo-password
```

より詳細なデプロイ・運用方法については、`hosts/` および `modules/` 配下の各 `README.md`（英語）を参照してください．

## CI/CD と自動化

GitHub Actions を利用して，構成の継続的インテグレーションと自動更新を行っています．

- **Nix Flake Check** (`nix-check.yml`): `main` や `feature/*`, `refactor/*` ブランチへのプッシュ，およびプルリクエスト時に自動で `nix flake check` を実行し，設定にエラーがないか検証します．
- **Scheduled Auto Update** (`auto-update.yml`): 毎日 04:00 JST に実行されます．`nvfetcher` による Minecraft プラグインの最新化と，`nix flake update` による `flake.lock` の更新を自動で行い，結果を `main` へコミットします．

## 参考文献

本構成の構築にあたり，多くの知見を以下のリポジトリから参考にさせていただきました．

- **[ryan4yin/nix-config](https://github.com/ryan4yin/nix-config)**: 全体的なモジュール構造と Niri 構成．
- **[natsukium/dotfiles](https://github.com/natsukium/dotfiles)**: Zen Browser の宣言的な詳細設定．
- **[asa1984/dotfiles](https://github.com/asa1984/dotfiles)**: NixOS および Home-manager 設定のベストプラクティス．
- **[ms0503/dotfiles](https://github.com/ms0503/dotfiles)**: 構造化されたモジュール設計．
- **[mkt3/dotfiles](https://github.com/mkt3/dotfiles)**: 高度な Noctalia 設定と日本語デスクトップ環境．
