# nix-config

[![Nix Flake Check](https://github.com/t3u-tsu/nix-config/actions/workflows/nix-check.yml/badge.svg)](https://github.com/t3u-tsu/nix-config/actions/workflows/nix-check.yml)
[![Scheduled Auto Update](https://github.com/t3u-tsu/nix-config/actions/workflows/auto-update.yml/badge.svg)](https://github.com/t3u-tsu/nix-config/actions/workflows/auto-update.yml)
![NixOS](https://img.shields.io/badge/NixOS-26.05-blue.svg?logo=NixOS&logoColor=white)
![Nix Flakes](https://img.shields.io/badge/Nix%20Flakes-Enabled-blueviolet.svg?logo=NixOS&logoColor=white)
[![License](https://img.shields.io/github/license/t3u-tsu/nix-config)](https://github.com/t3u-tsu/nix-config/blob/main/LICENSE)

[English](README.md)

Nix Flakes を用いてデスクトップ環境，タワーサーバー，およびネットワークゲートウェイを一元管理する宣言的設定リポジトリ．

## 技術スタック (Tech Stack)

| 構成要素 | 採用技術 |
| :--- | :--- |
| **OS** | NixOS 26.05 |
| **WM / コンポジタ** | niri (Wayland) |
| **バー / シェル** | Noctalia |
| **シェル** | zsh + pure + Atuin |
| **ターミナル** | Ghostty |
| **エディタ** | Neovim |
| **ブラウザ** | Zen Browser |
| **カラースキーム** | Vesper |
| **暗号化シークレット** | SOPS (sops-nix) + age |
| **メッシュ VPN** | Nebula |
| **バックアップ** | Restic + ZFS Mirror |
| **インフラ IaC** | OpenTofu |

## ディレクトリ構成

- [`flake.nix`](flake.nix) — flake-parts エントリポイント
- [`flake/`](flake/) — flake-parts サブモジュール群（`hosts`, `lib`, `overlays`, `packages`, `dev`）
- [`lib/`](lib/) — `mkSystem` システムビルダーおよび共通カラーパレット
- [`nixos/`](nixos/) — 全ホスト共通のシステムレベル NixOS モジュール群
- [`home/`](home/) — Home Manager ユーザー環境モジュール群
- [`hosts/`](hosts/) — マシン固有の設定・ハードウェア定義
- [`secrets/`](secrets/) — SOPS で暗号化された秘密情報
- [`scripts/`](scripts/) — クラスタ運用・保守スクリプト
- [`terraform/`](terraform/) — ConoHa VPS インフラの OpenTofu 定義
- [`docs/`](docs/) — 設計仕様，運用ランブック，ハードウェア解説，障害復旧手順（SSOT）

レイヤ評価順序や詳細なシステム構成は [`docs/architecture/overview.md`](docs/architecture/overview.md) を参照してください．運用手順や各ガイドの全目次は [`docs/README.md`](docs/README.md) に集約されています．

機密設定はプライベートリポジトリ（[`nix-config-private`](https://github.com/t3u-tsu/nix-config-private)）に分離して Flake 入力として参照しています．新規マシンのセットアップや初回認証ブートストラップは [`docs/operations/adding-a-host.md`](docs/operations/adding-a-host.md) を参照してください．

## クイックスタート

利用可能なホスト構成（`flake/hosts.nix` で定義）:

- **`x1c7`** — ラップトップ（ThinkPad X1 Carbon Gen 7）
- **`BrokenPC`** — メインワークステーション / ゲーミング（HP Victus 16-e1065AX）
- **`shosoin-tan`**, **`kagutsuchi-sama`**, **`sando-kun`** — タワーサーバークラスタ
- **`torii-chan-sd`** / **`torii-chan-hdd`** — Orange Pi Zero 3 SBC 上のエッジ VPN ゲートウェイ（SD / HDD ブート）
- **`torii-chan-vps`** — ConoHa VPS 上の待機系フェイルオーバーゲートウェイ（x86_64）
- **`torii-chan-sd-installer`** — SD カードインストーライメージ（`hosts/torii-chan/build-sd-image.sh`）
- **`torii-chan-vps-iso`** — VPS レスキューインストーラ ISO パッケージ（`nix build .#torii-chan-vps-iso`）

ローカルマシンへの設定適用:
```bash
sudo nixos-rebuild switch --flake .#BrokenPC
```

Nebula 経由でのリモートサーバーへのデプロイ:
```bash
nixos-rebuild switch --flake .#shosoin-tan --target-host t3u@10.0.0.4 --sudo --ask-sudo-password
```

SBC（`torii-chan`）へのリモートデプロイ:
```bash
nixos-rebuild switch --flake .#torii-chan-hdd --target-host t3u@10.0.0.1 --sudo --ask-sudo-password --option sandbox false --option filter-syscalls false
```

## 新規ホストの追加

[`docs/operations/adding-a-host.md`](docs/operations/adding-a-host.md) の統一手順書に従ってください．[`hosts/_template/`](hosts/_template) の複製，SOPS age 鍵の登録，Nebula 証明書の発行，デプロイ検証までの全工程が解説されています．

## CI/CD & 自動化

- **Nix Flake Check** ([`nix-check.yml`](.github/workflows/nix-check.yml)): 全ホストの評価と pre-commit リンター（`nixfmt`, `statix`, `shellcheck`, `ja-punctuation`），および `convco` による Conventional Commits コミット規約の検証を実施します．
- **Scheduled Auto Update** ([`auto-update.yml`](.github/workflows/auto-update.yml)): 毎日 04:00 JST に自動実行．nvfetcher による外部パッケージ追従，`flake.lock` の更新，CI 検証を経て自動で `main` に反映します．

## ドキュメント (Documentation)

アーキテクチャ設計，運用ランブック，ハードウェア解説，および障害復旧手順は [`docs/`](docs/) に集約されています．

- [ドキュメント目次: `docs/README.md`](docs/README.md)
- [アーキテクチャ・評価フロー: `docs/architecture/overview.md`](docs/architecture/overview.md)
- [ネットワークトポロジ・メッシュ VPN: `docs/architecture/network-topology.md`](docs/architecture/network-topology.md)
- [新ホスト追加手順: `docs/operations/adding-a-host.md`](docs/operations/adding-a-host.md)

## 参考文献 (References)

- https://github.com/ryan4yin/nix-config
- https://github.com/natsukium/dotfiles
- https://github.com/asa1984/dotfiles
- https://github.com/ms0503/dotfiles
- https://github.com/mkt3/dotfiles
