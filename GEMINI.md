# NixOS設定構築のコンテキスト

## 目的

`.` ディレクトリにて、Orange Pi Zero3 (`torii-chan`) 向けのNixOS設定を構築中。最終目標はSDカードイメージの生成と実機へのデプロイです。

## 現在の状況 (2025-12-29)

**デプロイ環境の安定化とDDNS認証の修正完了。**

### 達成したマイルストーン

1.  **実機セットアップ検証:**
    - Root SSH許可版のSDイメージで起動成功。
2.  **sops-nixの正常動作確認:**
    - `/var/lib/sops-nix/key.txt` に正しい age 秘密鍵を配置。
    - パスワードハッシュの反映に成功 (`users.mutableUsers = false` 設定済み)。
3.  **デプロイ権限の改善:**
    - `nix.settings.trusted-users = [ "root" "t3u" ]` を追加し、非特権ユーザーからのリモートデプロイを許可。
4.  **Cloudflare DDNSの修正:**
    - **Global API Key への対応**: `CF_API_EMAIL` と `CF_API_KEY` を使用する形式に `secrets.yaml` を修正。
    - タイムアウト延長 (`15s`) と IPv6 検出の無効化による安定化。

### 次のステップ

1.  **HDD移行の実行:**
    - `fs-hdd.nix` を適用し、ルートパーティションを外付けHDDへ移動する。
2.  **本番セキュリティの適用:**
    - 全ての設定が安定した後、LAN側のSSHポートを閉じ、WireGuard経由のみにする。

### デプロイコマンド
- SDイメージ作成: `nix build .#nixosConfigurations.torii-chan-sd.config.system.build.sdImage`
- 初回デプロイ (SD運用): `nix run nixpkgs#nixos-rebuild -- switch --flake .#torii-chan-sd-live --target-host root@10.0.0.1`
- 通常デプロイ (t3u使用): `nix run nixpkgs#nixos-rebuild -- switch --flake .#torii-chan-sd-live --target-host t3u@10.0.0.1 --use-remote-sudo`
