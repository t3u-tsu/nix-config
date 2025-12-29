# NixOS設定構築のコンテキスト

## 目的



Orange Pi Zero3 (`torii-chan`) 向けのNixOS設定を構築し、SD運用からHDD運用への移行準備を完了する。

## 現在の状況 (2025-12-29)

**全サービス（WireGuard, DDNS, sops-nix）の正常動作を確認。**

### 達成したマイルストーン

1.  **WireGuard**: サーバー起動およびクライアントからの `10.0.0.1` 経由の接続を確認。
2.  **sops-nix**: `key.txt` による復号、および `mutableUsers = false` によるパスワード同期の成功。
3.  **Cloudflare DDNS**: 
    - `favonia/cloudflare-ddns` が API Token 専用であることを特定。
    - 正しい API Token 形式への修正により、IP検出に成功。
4.  **デプロイ環境**: `trusted-users` の設定により、非特権ユーザーからのデプロイが可能になった。

### 確定した設定知識
- **DDNS**: `CLOUDFLARE_API_TOKEN` を使用し、`ip4Domains` で指定する。Global API Key は非対応。
- **Secrets**: `cloudflare_api_env` は `"CLOUDFLARE_API_TOKEN=..."` の 1 行形式が最も安定する。

### 次のステップ

1.  **HDD移行**: `fs-hdd.nix` を適用し、実データの移行を行う。
2.  **セキュリティ**: 全ての動作が安定したため、LAN側のSSHを閉じる。

### 主要コマンド
- デプロイ: `nix run nixpkgs#nixos-rebuild -- switch --flake .#torii-chan-sd-live --target-host t3u@10.0.0.1 --use-remote-sudo`