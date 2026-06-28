# NixOS Fleet 構成管理

Flakes を用いて、個人用のデスクトップおよびサーバー群の NixOS 設定を宣言的に一元管理するリポジトリです。

## 📂 ディレクトリ構造

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

## 🚀 クイックスタート

ローカルマシンの設定を適用する場合：

```bash
sudo nixos-rebuild switch --flake .#<hostname>
```

リモートマシン（例: Orange Pi Zero 3 の `torii-chan`）へデプロイする場合：

```bash
nixos-rebuild switch --flake .#torii-chan --target-host t3u@10.0.0.1 --use-remote-sudo --ask-sudo-password
```

より詳細なデプロイ・運用方法については、`hosts/` および `modules/` 配下の各 `README.md`（英語）を参照してください。