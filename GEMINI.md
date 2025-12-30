# NixOS設定構築 of torii-chan

## 目的

Orange Pi Zero3 (`torii-chan`) 向けのNixOS設定を構築し、SD運用からHDD運用への移行準備を完了する。

## 現在の状況 (2025-12-30)

**torii-chan: HDD移行完了。NIXOS_HDDをルートとして正常起動。**

**shosoin-tan: モニターアダプタ待ちのため一時中断。設定をLTSカーネルに同期済み。**



**kagutsuchi-sama: 新規追加。Disko によるディスク初期化・マウント完了。OSインストール（nixos-install）実施中。**







### 達成したマイルストーン







1.  **WireGuard**: サーバー起動およびクライアントからの `10.0.0.1` 経由の接続を確認。



2.  **sops-nix**: `key.txt` による復号、および `mutableUsers = false` によるパスワード同期の成功。



3.  **Cloudflare DDNS**: API Token による正常動作を確認。



4.  **デプロイ権限**: `trusted-users` 設定完了。



5.  **セキュリティ強化**: `production-security.nix` を適用し、SSHアクセスを WireGuard (wg0) 経由のみに制限済み。



6.  **shosoin-tan**: Core i7 870 / Quadro K2200 / ZFS Mirror 構成の初期設定を完了。



7.  **torii-chan HDD Boot Fix**: USBストレージ用カーネルモジュール (`uas`, `usb_storage`等) を `initrd` に追加し、`rootdelay` を設定。



8.  **torii-chan HDD移行**: `fs-hdd.nix` を適用し、実データの `rsync` および HDD 起動への移行に成功。



9.  **kagutsuchi-sama Disk ID**: 実機での `lsblk` により `by-id` を特定し、`disko-config.nix` に反映済み。



10. **kagutsuchi-sama Disko**: ライブUSB環境からの SSH リモート Disko 実行に成功。ディスクの初期化と `/mnt` へのマウントを完了。







### 次のステップ







1.  **kagutsuchi-sama OSインストール**: `nixos-install` を実行し、ブートローダーの設定を含めた環境構築を完了させる。



2.  **shosoin-tan 実機確認**: モニターアダプタ入手後、ディスクの `by-id` を確認し Disko 設定を最適化、インストール実施。











### 運用ルール (開発ワークフロー)

- 変更後は必ず `nix flake check` を実行し、構文エラーがないか確認する。

- ホスト追加や重要な変更の際は、`GEMINI.md` および `README.md` (日/英) を更新する。

- 変更はこまめに git commit する。



### 主要コマンド

- torii-chan デプロイ: `nix run nixpkgs#nixos-rebuild -- switch --flake .#torii-chan-sd-live --target-host t3u@10.0.0.1 --use-remote-sudo`

- shosoin-tan チェック: `nix flake check`

- 秘密情報の編集: `nix shell nixpkgs#sops -c sops secrets/secrets.yaml`
