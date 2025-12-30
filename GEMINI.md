# NixOS設定構築 of torii-chan

## 目的

Orange Pi Zero3 (`torii-chan`) 向けのNixOS設定を構築し、SD運用からHDD運用への移行準備を完了する。

## 現在の状況 (2025-12-31)

**torii-chan: HDD移行完了。NIXOS_HDDをルートとして正常起動。WireGuard管理ネットワーク(10.0.0.1)サーバーとして稼働中。**

**shosoin-tan: モニターアダプタ待ち。設定をLTSカーネルに同期済み。WireGuard(10.0.0.4)設定済み。**

**kagutsuchi-sama: セットアップ完了。WireGuard(10.0.0.3)経由でのSSHアクセスを確認。**

### 達成したマイルストーン

1.  **WireGuard (wg0)**: 管理用ネットワーク (10.0.0.0/24) を構築。全ホストでSSHをこのインターフェースのみに制限。
2.  **sops-nix**: `key.txt` による復号、および `mutableUsers = false` によるパスワード同期の成功。
3.  **Cloudflare DDNS**: API Token による正常動作を確認。
4.  **デプロイ権限**: `trusted-users` 設定完了。
5.  **セキュリティ強化**: `production-security.nix` を適用し、SSHアクセスを WireGuard (wg0) 経由のみに制限。
6.  **shosoin-tan**: Core i7 870 / Quadro K2200 / ZFS Mirror 構成の初期設定を完了。
7.  **torii-chan HDD Boot Fix**: USBストレージ用カーネルモジュール (`uas`, `usb_storage`等) を `initrd` に追加し、`rootdelay` を設定。
8.  **torii-chan HDD移行**: `fs-hdd.nix` を適用し、実データの `rsync` および HDD 起動への移行に成功。
9.  **kagutsuchi-sama Disk ID**: 実機での `lsblk` により `by-id` を特定し、`disko-config.nix` に反映済み。
10. **kagutsuchi-sama Disko**: ライブUSB環境からの SSH リモート Disko 実行に成功。
11. **kagutsuchi-sama OSインストール**: `nixos-install` を実行し、NVIDIAドライバビルドを含む全工程を完了。
12. **kagutsuchi-sama セットアップ完了**: 宣言的パスワード管理の導入と、実機での正常起動・動作を確認。
13. **WireGuard ネットワーク拡張**: `kagutsuchi-sama` (10.0.0.3) および `shosoin-tan` (10.0.0.4) を追加。管理用PCは `10.0.0.100`。
14. **アプリ間通信用ネットワーク (wg1)**: `10.0.1.0/24` を構築。サーバー間の自由な通信を許可。
15. **sando-kun 設定追加**: i7 860 / 250GB HDD 構成の初期設定を完了。WireGuard (10.0.0.2 / 10.0.1.2) 設定済み。
16. **Minecraftサーバー更新**: `lobby` を 1.21.4 (Latest) に更新し、ViaVersion / ViaBackwards を導入。

### 次のステップ

1.  **shosoin-tan 実機確認**: モニターアダプタ入手後、ディスクの `by-id` を確認し Disko 設定を最適化、インストール実施。

### 運用ルール (開発ワークフロー)

- 変更後は必ず `nix flake check` を実行し、構文エラーがないか確認する。
- ホスト追加や重要な変更の際は、`GEMINI.md` および `README.md` (日/英) を更新する。
- 変更はこまめに git commit する。

### 主要コマンド

- torii-chan デプロイ: `nix run nixpkgs#nixos-rebuild -- switch --flake .#torii-chan --target-host t3u@10.0.0.1 --sudo --ask-sudo-password`
- kagutsuchi-sama デプロイ: `nix run nixpkgs#nixos-rebuild -- switch --flake .#kagutsuchi-sama --target-host t3u@10.0.0.3 --sudo --ask-sudo-password`
- shosoin-tan チェック: `nix flake check`
- 秘密情報の編集: `nix shell nixpkgs#sops -c sops secrets/secrets.yaml`