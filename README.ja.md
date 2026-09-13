# nix-config

[![Nix Flake Check](https://github.com/t3u-tsu/nix-config/actions/workflows/nix-check.yml/badge.svg)](https://github.com/t3u-tsu/nix-config/actions/workflows/nix-check.yml)
[![Scheduled Auto Update](https://github.com/t3u-tsu/nix-config/actions/workflows/auto-update.yml/badge.svg)](https://github.com/t3u-tsu/nix-config/actions/workflows/auto-update.yml)
![NixOS](https://img.shields.io/badge/NixOS-26.05-blue.svg?logo=NixOS&logoColor=white)
![Nix Flakes](https://img.shields.io/badge/Nix%20Flakes-Enabled-blueviolet.svg?logo=NixOS&logoColor=white)
[![License](https://img.shields.io/github/license/t3u-tsu/nix-config)](https://github.com/t3u-tsu/nix-config/blob/main/LICENSE)

[English](README.md)

Flakes を用いてデスクトップやサーバー群の設定を一元管理しています．

## ディレクトリ構造

```text
.
├── flake.nix            # flake-parts エントリポイント
├── flake/               # flake-parts モジュール
│   ├── hosts.nix        # nixosConfigurations 定義
│   ├── lib.nix          # Flake ライブラリ出力
│   ├── overlays.nix     # Nixpkgs オーバーレイ
│   └── packages.nix     # Flake パッケージ出力
├── nixos/               # NixOS システムモジュール
│   ├── base/            # OS 基盤 (ユーザー, Nix, 時間同期)
│   ├── core/            # OS 核心設定 (i18n)
│   ├── security/        # セキュリティと秘密情報 (SOPS)
│   ├── networking/      # ネットワーク設定 (hosts, Nebula mesh)
│   ├── environment/     # システムパッケージ
│   ├── hardware/        # ハードウェア固有設定 (NVIDIA 等)
│   ├── dev-tools/       # 開発用ハードウェア・ツール (WCH-LinkE, Ventoy)
│   ├── profiles/        # 役割別プロファイル (desktop, tower-server, sbc, gateway)
│   ├── services/        # システムサービス (バックアップ, Minecraft, デスクトップ等)
│   └── virtualisation/  # 仮想化 (distrobox, microvm)
├── home/                # Home Manager モジュール
│   ├── shell/           # シェル環境 (Zsh, Pure, Atuin)
│   ├── programs/        # 共通ツール (CLI, Git, SSH)
│   └── desktop/         # デスクトップ環境 (Niri, ブラウザ, テーマ等)
├── hosts/               # ホスト固有設定（各ホストの README.md を参照）
│   ├── BrokenPC/        # ゲーミングラップトップ (Victus by HP)
│   ├── x1c7/            # ラップトップ (ThinkPad X1 Carbon Gen 7)
│   ├── torii-chan/      # VPN ゲートウェイ役割 (SBC aarch64 + VPS フェイルオーバー)
│   ├── shosoin-tan/     # タワーサーバー
│   ├── kagutsuchi-sama/ # タワーサーバー
│   └── sando-kun/       # タワーサーバー
├── lib/                 # ヘルパー関数 (mkSystem)
├── scripts/             # 運用スクリプト (Nebula CA ローテーション等)
├── secrets/             # SOPS 暗号化シークレット
└── terraform/           # OpenTofu: ConoHa VPS インフラ管理
```

## クイックスタート

利用可能な設定（`flake/hosts.nix` で定義）:

- **`BrokenPC`** — ゲーミングラップトップ（ローカルマシン）
- **`x1c7`** — ラップトップ（ThinkPad X1 Carbon Gen 7）
- **`shosoin-tan`**，**`kagutsuchi-sama`**，**`sando-kun`** — タワーサーバー
- **`torii-chan-sd`** / **`torii-chan-hdd`** — Orange Pi Zero 3 SBC 上の VPN ゲートウェイ（SD / HDD ルート）
- **`torii-chan-vps`** — フェイルオーバー VPS 上の同一ゲートウェイ役割（x86_64）
- **`torii-chan-sd-installer`** — SD インストーライメージ（`hosts/torii-chan/README.md` 参照）
- **`torii-chan-vps-iso`** — VPS インストーラ ISO．nixosConfiguration ではなく **package** として公開（`nix build .#torii-chan-vps-iso`）

ローカルマシンの設定を適用する場合：

```bash
sudo nixos-rebuild switch --flake .#BrokenPC
```

リモートマシン（例: Orange Pi Zero 3 の `torii-chan`）へデプロイする場合：

```bash
nixos-rebuild switch --flake .#torii-chan-hdd --target-host t3u@10.0.0.1 --sudo --ask-sudo-password --option sandbox false --option filter-syscalls false
```

`sandbox false` / `filter-syscalls false` フラグは，Orange Pi のカーネルが
`user_namespaces` / `seccomp BPF` に対応していないため必要です
（`hosts/torii-chan/README.md` のトラブルシューティング参照）．

## 新規ホストの追加

[`hosts/_template/`](hosts/_template) の雛形をコピーし，[`hosts/README.md`](hosts/README.md)（英語）のステップバイステップ手順に従ってください．`flake/hosts.nix` への登録，SOPS の鍵設定，Nebula 証明書の署名・import，検証，デプロイ，PR フローまでを扱っています．

より詳細なデプロイ・運用方法については，`hosts/`，`nixos/`，`home/` 配下の各 `README.md`（英語）を参照してください．

## CI/CD と自動化

GitHub Actions を利用して，構成の継続的インテグレーションと自動更新を行っています．

- **Nix Flake Check** (`nix-check.yml`): `main` や `feat/*`, `fix/*`, `refactor/*`, `docs/*`, `chore/*` ブランチへのプッシュ，およびプルリクエスト時に自動で `nix flake check` を実行し，設定にエラーがないか検証します．
- **Scheduled Auto Update** (`auto-update.yml`): 毎日 04:00 JST に実行されます．`nvfetcher` による Minecraft プラグインの最新化と，`nix flake update` による `flake.lock` の更新を自動で行い，結果を `main` へコミットします．

## 参考文献

本構成の構築にあたり，多くの知見を以下のリポジトリから参考にさせていただきました．

- **[ryan4yin/nix-config](https://github.com/ryan4yin/nix-config)**: 全体的なモジュール構造と Niri 構成．
- **[natsukium/dotfiles](https://github.com/natsukium/dotfiles)**: Zen Browser の宣言的な詳細設定．
- **[asa1984/dotfiles](https://github.com/asa1984/dotfiles)**: NixOS および Home-manager 設定のベストプラクティス．
- **[ms0503/dotfiles](https://github.com/ms0503/dotfiles)**: 構造化されたモジュール設計．
- **[mkt3/dotfiles](https://github.com/mkt3/dotfiles)**: 高度な Noctalia 設定と日本語デスクトップ環境．
