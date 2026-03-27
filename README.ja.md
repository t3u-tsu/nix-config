# NixOS 構成管理リポジトリ

このリポジトリは、NixOSのマルチホスト構成を Flakes と **Modular Architecture** を用いて管理しています。

## 📂 ディレクトリ構造

リポジトリは「仕組み（Modules）」と「実体（Hosts）」に分かれています。

```text
.
├── flake.nix           # 構成のエントリポイント
├── hosts/              # ホスト固有の設定 (torii-chan, shosoin-tan, etc.)
└── modules/            # 再利用可能なモジュール集
    ├── core/           # 基盤設定 (Nix, Network, User, Sops)
    ├── packages/       # システムパッケージ群 (base, monitoring, etc.)
    ├── home/           # Home-manager によるユーザー環境 (Shell, Desktop, SSH)
    ├── services/       # 各種サービス (Minecraft, Update Hub, Desktop)
    └── profiles/       # 役割ごとのプロファイル (Desktop, Tower Server)
```

## 🚀 デプロイと反映

`main` ブランチに Push された変更は、**comin** によって5分おきに全ホストへ自動的に Pull され、反映されます。手動のトリガーや中央サーバーへの通知は不要です。

## 🛠️ 主な機能

- **Modular Architecture**: システム層 (NixOS) とユーザー層 (Home-manager) を明確に分離。
- **Modern CLI Tools**: Starship, Atuin, Zellij, Yazi, fzf, ripgrep 等を全ホストで標準化。
- **Desktop Environment**: Zen Browser (宣言的設定), Vesktop, Neovim, Alacritty による最強のデスクトップ体験。
- **Smart Hardware Tools**: `my.hardware.pc-tools.enable = true` で物理サーバー用ツールをオプトイン。
- **Fleet Monitoring Dashboard**: Prometheus と Grafana を統合し、全ホストから集約したメトリクスを `torii-chan` 上のダッシュボードで一元管理。
- **sops-nix**: `age` を用いた機密情報の暗号化管理。
- **Automated Backup**: Restic による自動バックアップ (shosoin-tan)。

詳細は [GEMINI.md](GEMINI.md) または各モジュールの `README.md` を参照してください。

## 📚 参考文献 (References)

本構成の構築にあたり、多くの知見を以下のリポジトリから参考にさせていただきました：

- **[ryan4yin/nix-config](https://github.com/ryan4yin/nix-config)**: 全体的なモジュール構造と Niri 構成。
- **[omarchy-nix](https://github.com/henrysipp/omarchy-nix)**: 快適なキーバインド（Omarchy スタイル）の設計。
- **[natsukium/dotfiles](https://github.com/natsukium/dotfiles)**: Zen Browser の宣言的な詳細設定。
- **[asa1984/dotfiles](https://github.com/asa1984/dotfiles)**: NixOS および Home-manager 設定のベストプラクティス。
- **[ms0503/dotfiles](https://github.com/ms0503/dotfiles)**: 構造化されたモジュール設計。
- **[mkt3/dotfiles](https://github.com/mkt3/dotfiles)**: 高度な Noctalia Shell 設定と日本語デスクトップ環境。