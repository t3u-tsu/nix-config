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
3.  **Cloudflare DDNS**: API Token による正常動作を確認。`mc.t3u.uk` および `*.mc.t3u.uk` を追加。
4.  **デプロイ権限**: `trusted-users` 設定完了。
5.  **セキュリティ強化**: `production-security.nix` を適用し、SSHアクセスを WireGuard (wg0) 経由のみに制限。
6.  **shosoin-tan**: Core i7 870 / Quadro K2200 / ZFS Mirror 構成の初期設定を完了。
7.  **torii-chan HDD Boot Fix**: USBストレージ用カーネルモジュール (`uas`, `usb_storage`等) を `initrd` に追加し、`rootdelay` を設定。
8.  **torii-chan HDD移行**: `fs-hdd.nix` を適用し、実データの `rsync` および HDD 起動への移行に成功。
9.  **kagutsuchi-sama Disk ID**: 実機での `lsblk` により `by-id` を特定し、`disko-config.nix` に反映済み。
10. **kagutsuchi-sama Disko**: ライブUSB環境からの SSH リモート Disko 実行に成功。
11. **kagutsuchi-sama OSインストール**: `nixos-install` を実行し、NVIDIAドライバビルドを含む全工程を完了。
12. **kagutsuchi-sama セットアップ完了**: 宣言的パスワード管理の導入と、実機での正常起動・動作を確認。
13. **WireGuard ネットワーク拡張**: `kagutsuchi-sama` (10.0.0.3) および `shosoin-tan` (10.0.0.4) を追加. 管理用PCは `10.0.0.100`。
14. **アプリ間通信用ネットワーク (wg1)**: `10.0.1.0/24` を構築。サーバー間の自由な通信を許可。
15. sando-kun 設定追加: i7 860 / 250GB HDD 構成の初期設定を完了。WireGuard (10.0.0.2 / 10.0.1.2) 設定済み。
16. nitac23s 移行完了: 旧サーバーからのワールドデータ (world, nether, end)、usercache、whitelist の移行および Kagutsuchi-sama での稼働を確認。
17. 基本ツールのモジュール化: 全ホスト共通の基本ツール (`vim`, `git`, `tmux`, `htop`, `rsync` 等) を `common/` に集約し、保守性を向上。
18. Cloudflare DDNS 拡張: `mc.t3u.uk` および `*.mc.t3u.uk` を追加し、Minecraft ネットワーク用のドメイン運用を開始。
19. Velocity 構成の最適化: `forced-hosts` を Nix 式で動的に生成するように変更。`mc.t3u.uk` を `lobby` に、`nitac23s.mc.t3u.uk` を `nitac23s` にマッピング。
20. Lobby サーバーの Void 化: 既存ワールドをリセットし、一切のブロックがない Void ワールドとして再構築。
21. プラグイン自動更新の導入: `nvfetcher` を導入し、ViaVersion/ViaBackwards を常に最新の GitHub リリースから取得してビルドする仕組みを構築。
22. サーバー警告の解消: `LD_LIBRARY_PATH` への `udev` 追加によるライブラリ不足警告の修正、および `paper-global.yml` の `config-version` 指定による警告の解消。
23. 自動更新システムの構築: 毎日午前4時に `nix flake update`、`nvfetcher` 更新、Git コミット＆プッシュ、`nixos-rebuild switch` を自動実行する Systemd Timer を構築。
24. 自動更新モジュールのリファクタリング: `config.users.users` によるパスの動的解決と、未踏環境での自動クローン（セルフヒーリング）機能を実装。
25. Kagutsuchi-sama 障害復旧と接続性改善: 同じ LAN 内での NAT ループバック問題による VPN 不通を解消するため、`/etc/hosts` によるローカル解決を導入。救出用の一時的な LAN SSH 許可を経て、セキュアな元の状態へ復元。

### 次のステップ

1.  **shosoin-tan 実機確認**: モニターアダプタ入手後、ディスクの `by-id` を確認し Disko 設定を最適化、インストール実施。
2.  **共通設定の拡充**: シェルの設定 (zsh/fish) や alias など、全ホストで共通化したい設定を `common/` に追加していく。
3.  **自動更新ログの通知**: 更新失敗時に Discord 等へ通知する仕組みの検討。

### 運用ルール (開発ワークフロー)

- **文書管理**: トップレベルの `README` を整理する際は、ホスト一覧や全体構造などの「プロジェクト俯瞰に必要な共通概要事項」を削除しないこと。詳細はサブディレクトリの `README` に任せつつ、全体像はトップレベルで維持し、各所への誘導を行う。
- 変更後は必ず `nix flake check` を実行し、構文エラーがないか確認する。
- ホスト追加や重要な変更の際は、`GEMINI.md` および `README.md` (日/英) を更新する。
- 変更はこまめに git commit する。

### 主要コマンド

- torii-chan デプロイ: `nix run nixpkgs#nixos-rebuild -- switch --flake .#torii-chan --target-host t3u@10.0.0.1 --sudo --ask-sudo-password`
- kagutsuchi-sama デプロイ: `nix run nixpkgs#nixos-rebuild -- switch --flake .#kagutsuchi-sama --target-host t3u@10.0.0.3 --sudo --ask-sudo-password`
- shosoin-tan チェック: `nix flake check`
- 秘密情報の編集: `nix shell nixpkgs#sops -c sops secrets/secrets.yaml`
