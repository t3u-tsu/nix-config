# NixOS設定構築のコンテキスト

## 目的

Orange Pi Zero3 (`torii-chan`) 向けのNixOS設定を構築し、SD運用からHDD運用への移行準備を完了する。

## 現在の状況 (2025-12-29)

**デバッグ完了・全サービス正常動作確認済み。ドキュメントおよびコードの整理完了。**

### 達成したマイルストーン

1.  **sops-nix の完全復旧**:
    - `/var/lib/sops-nix/key.txt` の手動配置と `SOPS_AGE_KEY_FILE` 環境変数の設定。
    - `users.mutableUsers = false` により、復号されたパスワードハッシュの `/etc/shadow` への強制同期に成功。
    - `sshKeyPaths = []` と `generateKey = false` により、意図しない鍵の使用と生成を防止。
2.  **Cloudflare DDNS の正常化**:
    - 認証方式を Global API Key から API Token に修正（ツール側の制約に対応）。
    - `ip4Domains` / `ip6Domains` の正しいオプション名への修正。
    - `detectionTimeout = "15s"` 延長と `restartUnits` 追加による堅牢化。
3.  **デプロイ環境の改善**:
    - `nix.settings.trusted-users = [ "root" "t3u" ]` により、署名エラーなしでの非特権ユーザーデプロイを実現。
4.  **メンテナンス性の向上**:
    - 全てのコードコメントを英語に翻訳。
    - ホスト固有の詳細手順を `hosts/torii-chan/README.md` へ分離。
    - 表記を「Orange Pi Zero3」に統一。

### 次のステップ

1.  **HDD移行の実行**:
    - `fs-hdd.nix` を適用し、ルートパーティションを外付けHDDへ移動する（詳細は `hosts/torii-chan/README.md` 参照）。
2.  **最終セキュリティ強化**:
    - LAN側のSSHを閉じ、通信をWireGuard経由に限定する。

### 主要コマンド
- デプロイ (推奨): `nix run nixpkgs#nixos-rebuild -- switch --flake .#torii-chan-sd-live --target-host t3u@10.0.0.1 --use-remote-sudo`
- 秘密情報の編集: `nix shell nixpkgs#sops -c sops secrets/secrets.yaml`
