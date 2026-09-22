# nix-config

[![Nix Flake Check](https://github.com/t3u-tsu/nix-config/actions/workflows/nix-check.yml/badge.svg)](https://github.com/t3u-tsu/nix-config/actions/workflows/nix-check.yml)
[![Scheduled Auto Update](https://github.com/t3u-tsu/nix-config/actions/workflows/auto-update.yml/badge.svg)](https://github.com/t3u-tsu/nix-config/actions/workflows/auto-update.yml)
![NixOS](https://img.shields.io/badge/NixOS-26.05-blue.svg?logo=NixOS&logoColor=white)
![Nix Flakes](https://img.shields.io/badge/Nix%20Flakes-Enabled-blueviolet.svg?logo=NixOS&logoColor=white)
[![License](https://img.shields.io/github/license/t3u-tsu/nix-config)](https://github.com/t3u-tsu/nix-config/blob/main/LICENSE)

[English](README.md)

Flakes を用いてデスクトップやサーバー群の設定を一元管理しています．

## スタック

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

## ディレクトリ構造

- [`flake.nix`](flake.nix) — flake-parts エントリポイント
- [`flake/`](flake/) — flake-parts モジュール (hosts, lib, overlays, packages, dev)
- [`lib/`](lib/) — mkSystem ヘルパーと共通カラーパレット
- [`nixos/`](nixos/) — 全ホスト共通のシステムモジュール
- [`home/`](home/) — home-manager モジュール
- [`hosts/`](hosts/) — マシン固有の設定
- [`secrets/`](secrets/) — SOPS 暗号化シークレット
- [`scripts/`](scripts/) — 運用スクリプト
- [`terraform/`](terraform/) — ConoHa VPS インフラ

各層の読み込み方は [`docs/architecture.md`](docs/architecture.md) に書いています．

公開したくない個人データ（Zen の pin，ダッシュボードの URL など）は private リポジトリ
[`nix-config-private`](https://github.com/t3u-tsu/nix-config-private) に置き，
`flake = false` の input として読み込んでいます．この flake を評価するホストは
すべて読み取り権限が必要で，`nixos/base/nix.nix` が `secrets/common.yaml` の
read-only deploy key と，それを指す `github-nix-config-private` という ssh エイリアスを用意します．

## クイックスタート

利用可能な設定（`flake/hosts.nix` で定義）:

- **`x1c7`** — ラップトップ（ThinkPad X1 Carbon Gen 7）
- **`BrokenPC`** — ゲーミングラップトップ（HP Victus 16-e1065AX）
- **`shosoin-tan`**，**`kagutsuchi-sama`**，**`sando-kun`** — タワーサーバー
- **`torii-chan-sd`** / **`torii-chan-hdd`** — Orange Pi Zero 3 SBC 上の VPN ゲートウェイ（SD / HDD ルート）
- **`torii-chan-vps`** — フェイルオーバー VPS 上の同一ゲートウェイ役割（x86_64）
- **`torii-chan-sd-installer`** — SD インストーライメージ（[`hosts/torii-chan/README.md`](hosts/torii-chan/README.md) 参照）
- **`torii-chan-vps-iso`** — VPS インストーラ ISO．nixosConfiguration ではなく **package** として公開（`nix build .#torii-chan-vps-iso`）

ローカルマシンの設定を適用する場合：

```bash
sudo nixos-rebuild switch --flake .#BrokenPC
```

リモートマシン（例: Orange Pi Zero 3 の `torii-chan`）へデプロイする場合：

```bash
nixos-rebuild switch --flake .#torii-chan-hdd --target-host t3u@10.0.0.1 --sudo --ask-sudo-password --option sandbox false --option filter-syscalls false
```

`sandbox false` / `filter-syscalls false` フラグは，Orange Pi のカーネルが `user_namespaces` / `seccomp BPF` に対応していないため必要です（[`hosts/torii-chan/README.md`](hosts/torii-chan/README.md) 参照）．

## 新規ホストの追加

[`hosts/_template/`](hosts/_template) をコピーし，[`hosts/README.md`](hosts/README.md)（英語）に従ってください．登録，SOPS の鍵，Nebula 証明書，デプロイの手順を扱っています．

## CI/CD と自動化

- **Nix Flake Check** (`nix-check.yml`): `main` または `feat/` `fix/` `refactor/` `docs/` `chore/` ブランチへのプッシュと，`main` へのプルリクエストで実行．一方のジョブが `nix flake check`（全ホストの評価と整形・lint フック），もう一方が `convco` によるコミットメッセージの検査を行う．
- **Scheduled Auto Update** (`auto-update.yml`): 毎日 04:00 JST にピン留めしたソース（`nvfetcher`: Minecraft プラグインと Zen のユーザースクリプト）と `flake.lock` を更新し，`nix flake check` で検証して `main` へ直接コミット．

## 参考文献

- https://github.com/ryan4yin/nix-config
- https://github.com/natsukium/dotfiles
- https://github.com/asa1984/dotfiles
- https://github.com/ms0503/dotfiles
- https://github.com/mkt3/dotfiles
