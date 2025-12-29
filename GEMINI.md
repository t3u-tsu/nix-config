# NixOS設定構築のコンテキスト

## 目的

`.` ディレクトリにて、Orange Pi Zero3 (`torii-chan`) 向けのNixOS設定を構築中。最終目標はSDカードイメージの生成と実機へのデプロイです。

## 現在の状況 (2025-12-29)

**SDイメージとHDD運用設定の準備完了。DDNS, WireGuardの基本設定を追加。**

### 達成したマイルストーン

1.  **SD/HDD構成の確立:**
    - `torii-chan-sd`: 初期インストール用SDイメージ。
    - `torii-chan`: HDDルート運用/デプロイ用。
    - 初回起動時のロックアウト回避策 (sudoパスワードなし) を実装。
2.  **SOPS鍵の再生成:** 秘密鍵紛失のため再暗号化済み。
3.  **サービス設定の追加:**
    - `hosts/torii-chan/services/` ディレクトリを作成。
    - `ddns.nix`: Cloudflare DDNS (`services.cloudflare-dyndns`) を設定。
    - `wireguard.nix`: WireGuardサーバーの基本設定。
    - シークレットはSOPS経由で管理。

### 次のステップ（シークレット設定）

以下のシークレットを `secrets/secrets.yaml` に追加する必要がある。
- `cloudflare_api_token`: DDNS用APIトークン。
- `torii_chan_wireguard_private_key`: WireGuardサーバー秘密鍵。

### デプロイフロー

1.  **SDカード作成 & 初回起動:**
    - `nix build .#nixosConfigurations.torii-chan-sd.config.system.build.sdImage`
    - 起動後、SSHでログインし `/var/lib/sops-nix/key.txt` を配置。
2.  **HDD移行作業 (実機上):**
    - HDDフォーマット & データコピー。
3.  **設定適用 (リモート):**
    - `nixos-rebuild switch --flake .#torii-chan --target-host ...` を実行。

## デプロイコマンド
- SDイメージ作成: `nix build .#nixosConfigurations.torii-chan-sd.config.system.build.sdImage`
- リモート更新 (HDD構成): `nixos-rebuild switch --flake .#torii-chan --target-host t3u@192.168.0.128 --use-remote-sudo`

