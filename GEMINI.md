# NixOS設定構築のコンテキスト

## 目的

`.` ディレクトリにて、Orange Pi Zero3 (`torii-chan`) 向けのNixOS設定を構築中。最終目標はSDカードイメージの生成と実機へのデプロイです。

## 現在の状況 (2025-12-29)

**sops-nixのデバッグ完了、デプロイ成功。**

### 達成したマイルストーン

1.  **実機セットアップ検証:**
    - Root SSH許可版のSDイメージで起動成功。
2.  **sops-nixの正常動作確認:**
    - `/var/lib/sops-nix/key.txt` に正しい age 秘密鍵を配置。
    - `/run/secrets/` への展開を確認。
    - `configuration.nix` にて `sops.age.sshKeyPaths = []` と `sops.age.generateKey = false` を設定し、挙動を安定化。
3.  **パスワードハッシュの反映:**
    - `users.mutableUsers = false` を設定し、`sops-nix` で復号されたハッシュが確実に `/etc/shadow` に反映されるように修正。
4.  **Cloudflare DDNSの修正:**
    - `secrets.yaml` 内のインデント問題を解消。
    - `ddns.nix` にて正しいオプション名 `ip4Domains` / `ip6Domains` を使用するように修正。
    - IPv6検出エラー回避のため、IPv4のみを更新する設定に変更。

### 次のステップ

1.  **HDD移行の最終確認:**
    - `fs-hdd.nix` と `torii-chan` ターゲットを使用した HDD ブートの検証。
2.  **本番セキュリティの適用:**
    - WireGuard経由でのSSHアクセスが安定していることを確認し、LAN側SSHを閉じる。

### デプロイコマンド
- SDイメージ作成: `nix build .#nixosConfigurations.torii-chan-sd.config.system.build.sdImage`
- 初回デプロイ (SD運用): `nix run nixpkgs#nixos-rebuild -- switch --flake .#torii-chan-sd-live --target-host root@192.168.0.128`
- 本番デプロイ (HDD運用): `nix run nixpkgs#nixos-rebuild -- switch --flake .#torii-chan --target-host t3u@192.168.0.128 --use-remote-sudo`