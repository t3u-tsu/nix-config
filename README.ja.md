# nix-config

[![Nix Flake Check](https://github.com/t3u-tsu/nix-config/actions/workflows/nix-check.yml/badge.svg)](https://github.com/t3u-tsu/nix-config/actions/workflows/nix-check.yml)
[![Scheduled Auto Update](https://github.com/t3u-tsu/nix-config/actions/workflows/auto-update.yml/badge.svg)](https://github.com/t3u-tsu/nix-config/actions/workflows/auto-update.yml)
![NixOS](https://img.shields.io/badge/NixOS-26.05-blue.svg?logo=NixOS&logoColor=white)
![Nix Flakes](https://img.shields.io/badge/Nix%20Flakes-Enabled-blueviolet.svg?logo=NixOS&logoColor=white)
[![License](https://img.shields.io/github/license/t3u-tsu/nix-config)](https://github.com/t3u-tsu/nix-config/blob/main/LICENSE)

[English](README.md)

Nix Flakes でワークステーション，サーバー群，ネットワークゲートウェイを一元管理する宣言的 NixOS 設定．

## 技術スタック

| 構成要素 | 採用技術 |
| :--- | :--- |
| OS | NixOS 26.05 |
| WM / コンポジタ | niri (Wayland) |
| デスクトップシェル / バー | Noctalia |
| シェル | zsh + pure + Atuin |
| ターミナル | Ghostty |
| エディタ | Neovim |
| ブラウザ | Zen Browser |
| カラーテーマ | Vesper |
| シークレット管理 | agenix-rekey + agenix + age |
| メッシュ VPN | Nebula |
| バックアップ | Restic + ZFS Mirror |
| IaC | OpenTofu |

## ディレクトリ構成

- [flake.nix](flake.nix) — flake-parts エントリポイント
- [flake/](flake/) — flake-parts モジュール群 (`hosts`, `lib`, `overlays`, `packages`, `dev`)
- [lib/](lib/) — `mkSystem` システムビルダー，共通カラーパレット (`palette.nix`)，agenix マスター識別子 (`agenix.nix`)
- [nixos/](nixos/) — 全ホスト共通のシステムレベル NixOS モジュール群
- [home/](home/) — Home Manager ユーザー環境モジュール群
- [hosts/](hosts/) — マシン固有の設定・ハードウェア定義
- [secrets/](secrets/) — agenix-rekey で暗号化された秘密情報
- [scripts/](scripts/) — クラスタ運用・保守スクリプト
- [terraform/](terraform/) — ConoHa VPS インフラの OpenTofu 定義
- [docs/](docs/) — 設計仕様，運用手順書，ハードウェア解説，障害復旧手順

システムアーキテクチャとモジュール評価フローは [docs/architecture/overview.md](docs/architecture/overview.md) を参照．

機密情報はプライベートリポジトリ ([nix-config-private](https://github.com/t3u-tsu/nix-config-private))に分離し，Flake input として読み込む．マシン初期設定や初回認証ブートストラップは [docs/operations/adding-a-host.md](docs/operations/adding-a-host.md) を参照．

## クイックスタート

利用可能なホスト構成 ([flake/hosts.nix](flake/hosts.nix) で定義):

| 構成名 | 役割・対象環境 |
| :--- | :--- |
| `x1c7` | メインラップトップ (ThinkPad X1 Carbon Gen 7) |
| `BrokenPC` | 可搬ゲーミングノートPC (HP Victus 16-e1065AX) |
| `shosoin-tan`, `kagutsuchi-sama`, `sando-kun` | タワーサーバークラスタ |
| `torii-chan-sd` / `torii-chan-hdd` | Orange Pi Zero 3 SBC 上のエッジ VPN ゲートウェイ (SD / HDD ブート) |
| `torii-chan-vps` | ConoHa VPS 上のフェイルオーバーゲートウェイ (x86_64) |
| `torii-chan-sd-installer` | SD カードインストーライメージ ([hosts/torii-chan/build-sd-image.ysh](hosts/torii-chan/build-sd-image.ysh)) |
| `torii-chan-vps-iso` | VPS レスキューインストーラ ISO パッケージ (`nix build .#torii-chan-vps-iso`) |

ローカルマシンへの設定適用:
```bash
sudo nixos-rebuild switch --flake .#BrokenPC
```

Nebula 経由でのリモートサーバーへのデプロイ:
```bash
nixos-rebuild switch --flake .#shosoin-tan --target-host t3u@10.0.0.4 --sudo --ask-sudo-password
```

SBC (`torii-chan`)へのリモートデプロイ:
```bash
nixos-rebuild switch --flake .#torii-chan-hdd --target-host t3u@10.0.0.1 --sudo --ask-sudo-password --option sandbox false --option filter-syscalls false
```

## 新規ホストの追加

新規ホストのセットアップ手順は [docs/operations/adding-a-host.md](docs/operations/adding-a-host.md) を参照 ([hosts/_template/](hosts/_template) の複製，agenix ホスト鍵登録，Nebula 証明書発行，デプロイ検証)．

## CI/CD & 自動化

| ワークフロー | トリガー・内容 |
| :--- | :--- |
| [Nix Flake Check](.github/workflows/nix-check.yml) | 全ホストの評価，pre-commit リンター (`nixfmt`, `statix`, `ysh-check`, `shellcheck`, `ja-punctuation`, `docs-check`) の実行，`convco` による Conventional Commits 検証 |
| [Scheduled Auto Update](.github/workflows/auto-update.yml) | 毎日 04:00 JST に実行．nvfetcher による外部パッケージ追従，[flake.lock](flake.lock) 更新，CI 検証を経て `main` へ反映 |

## ドキュメント

運用手順書，アーキテクチャ設計，ハードウェア仕様，障害復旧手順の目次は [docs/README.md](docs/README.md) を参照．

## 参考文献

- https://github.com/ryan4yin/nix-config
- https://github.com/natsukium/dotfiles
- https://github.com/asa1984/dotfiles
- https://github.com/ms0503/dotfiles
- https://github.com/mkt3/dotfiles
