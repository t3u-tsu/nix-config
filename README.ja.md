# nix-config

[![Nix Flake Check](https://github.com/t3u-tsu/nix-config/actions/workflows/nix-check.yml/badge.svg)](https://github.com/t3u-tsu/nix-config/actions/workflows/nix-check.yml)
[![Scheduled Auto Update](https://github.com/t3u-tsu/nix-config/actions/workflows/auto-update.yml/badge.svg)](https://github.com/t3u-tsu/nix-config/actions/workflows/auto-update.yml)
![NixOS](https://img.shields.io/badge/NixOS-26.05-blue.svg?logo=NixOS&logoColor=white)
![Nix Flakes](https://img.shields.io/badge/Nix%20Flakes-Enabled-blueviolet.svg?logo=NixOS&logoColor=white)
[![License](https://img.shields.io/github/license/t3u-tsu/nix-config)](https://github.com/t3u-tsu/nix-config/blob/main/LICENSE)

[English](README.md)

Nix Flakes を用いて，デスクトップ環境や各種サーバーの設定を一元管理しています．

## 構成技術スタック

|                  |                    |
| ---------------- | ------------------ |
| **OS**           | NixOS 26.05        |
| **WM**           | niri               |
| **バー**         | Noctalia           |
| **シェル**       | zsh + pure + Atuin |
| **ターミナル**   | Ghostty            |
| **エディタ**     | Neovim             |
| **ブラウザ**     | Zen Browser        |
| **テーマ**       | Vesper             |
| **シークレット** | SOPS               |
| **VPN**          | Nebula             |
| **バックアップ** | restic             |
| **IaC**          | OpenTofu           |

## ディレクトリ構成

- [`flake.nix`](flake.nix) — flake-parts のエントリポイント
- [`flake/`](flake/) — flake-parts モジュール（hosts，lib，overlays，packages，dev）
- [`lib/`](lib/) — `mkSystem` ヘルパー関数および共通カラーパレット
- [`nixos/`](nixos/) — 全ホスト共通のシステムモジュール
- [`home/`](home/) — Home Manager モジュール
- [`hosts/`](hosts/) — マシン固有の設定
- [`secrets/`](secrets/) — SOPS で暗号化したシークレット
- [`scripts/`](scripts/) — 運用保守用スクリプト
- [`terraform/`](terraform/) — ConoHa VPS のインフラ定義

各レイヤーの読み込み順や依存関係の詳細は [`docs/architecture.md`](docs/architecture.md) を参照してください．

非公開にしたい個人データは，プライベートリポジトリ [`nix-config-private`](https://github.com/t3u-tsu/nix-config-private) に分離して読み込んでいます．
この Flake を評価するすべてのホストで読み取り権限が必要となるため，`nixos/base/private-config.nix` が `secrets/common.yaml` 内の読み取り専用デプロイキーと，それを参照する SSH エイリアス `github-nix-config-private` を自動設定します．ただし，本モジュールが未適用のホスト（OS 新規インストール時や private input 導入前のマシンなど）では Flake の評価自体に失敗するため，初回のみ root の SSH 設定を手動で行い入力ソースを取得できるようにする必要があります．具体的な手順は [hosts/README.md](hosts/README.md#bootstrap-the-private-flake-input) を参照してください．

## クイックスタート

利用可能なホスト設定（`flake/hosts.nix` で定義）：

- **`x1c7`** — ノート PC（ThinkPad X1 Carbon Gen 7）
- **`BrokenPC`** — ゲーミングノート PC（HP Victus 16-e1065AX）
- **`shosoin-tan`**，**`kagutsuchi-sama`**，**`sando-kun`** — 自宅タワーサーバー群
- **`torii-chan-sd`** / **`torii-chan-hdd`** — Orange Pi Zero 3 SBC 上の VPN ゲートウェイ（SD / HDD ルート起動）
- **`torii-chan-vps`** — フェイルオーバー用 VPS 上の同一ゲートウェイ（x86_64）
- **`torii-chan-sd-installer`** — SD カード用インストーライメージ（[`hosts/torii-chan/README.md`](hosts/torii-chan/README.md) 参照）
- **`torii-chan-vps-iso`** — VPS 用インストーラ ISO（nixosConfiguration ではなく **package** として公開: `nix build .#torii-chan-vps-iso`）

ローカルマシンの設定を適用する場合：

```bash
sudo nixos-rebuild switch --flake .#BrokenPC
```

リモートマシン（例: Orange Pi Zero 3 の `torii-chan`）へデプロイする場合：

```bash
nixos-rebuild switch --flake .#torii-chan-hdd --target-host t3u@10.0.0.1 --sudo --ask-sudo-password --option sandbox false --option filter-syscalls false
```

※ Orange Pi のカーネルが `user_namespaces` および `seccomp BPF` に対応していないため，`--option sandbox false` と `--option filter-syscalls false` フラグの指定が必要です（詳細は [`hosts/torii-chan/README.md`](hosts/torii-chan/README.md) 参照）．

## 新規ホストの追加

[`hosts/_template/`](hosts/_template) を複製し，[`hosts/README.md`](hosts/README.md)（英語）の手順に従ってください．ホストの登録，SOPS 鍵の設定，Nebula 証明書の発行，デプロイまでの流れをまとめています．

## CI/CD と自動化

- **Nix Flake Check** ([`nix-check.yml`](.github/workflows/nix-check.yml)): `main` ブランチへのプッシュおよびプルリクエスト時に実行されます．1 つのジョブで `nix flake check`（全ホストの評価，コード整形，lint フック）を検証し，もう 1 つのジョブで `convco` によるコミットメッセージの規約検査を行います．
- **Scheduled Auto Update** ([`auto-update.yml`](.github/workflows/auto-update.yml`)): 毎日 04:00 JST に実行されます．nvfetcher によるパッケージソースの同期と `flake.lock` の更新を行い，`nix flake check` で検証が通った変更を `main` ブランチへ自動コミットします．

## 参考文献

- https://github.com/ryan4yin/nix-config
- https://github.com/natsukium/dotfiles
- https://github.com/asa1984/dotfiles
- https://github.com/ms0503/dotfiles
- https://github.com/mkt3/dotfiles
