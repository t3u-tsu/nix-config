# NixOS設定構築 of torii-chan

## 目的

Orange Pi Zero3 (`torii-chan`) 向けのNixOS設定を構築し、SD運用からHDD運用への移行準備を完了する。

## 現在の状況 (2025-12-30)

**デバッグ完了・全サービス正常動作確認済み。セキュリティ強化（SSH制限）も適用済み。**

### 達成したマイルストーン

1.  **WireGuard**: サーバー起動およびクライアントからの `10.0.0.1` 経由の接続を確認。
2.  **sops-nix**: `key.txt` による復号、および `mutableUsers = false` によるパスワード同期の成功。
3.  **Cloudflare DDNS**: API Token による正常動作を確認。
4.  **デプロイ権限**: `trusted-users` 設定完了。
5.  **セキュリティ強化**: `production-security.nix` を適用し、SSHアクセスを WireGuard (wg0) 経由のみに制限済み。

### 次のステップ

1.  **HDD移行**: `fs-hdd.nix` を適用し、実データの移行を行う。

### 主要コマンド
- デプロイ: `nix run nixpkgs#nixos-rebuild -- switch --flake .#torii-chan-sd-live --target-host t3u@10.0.0.1 --use-remote-sudo`
- 秘密情報の編集: `nix shell nixpkgs#sops -c sops secrets/secrets.yaml`