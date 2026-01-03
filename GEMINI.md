# NixOS設定構築 of torii-chan

## 目的

Orange Pi Zero3 (`torii-chan`) 向けのNixOS設定を構築し、SD運用からHDD運用への移行準備を完了する。

## 現在の状況 (2026-01-03)

**torii-chan: Coordinated Update Hubとして稼働中。10.0.1.1:8080 (App) / 10.0.0.1:8080 (Mgmt) でステータスを提供。**

**shosoin-tan: Minecraft サーバー兼 Coordinated Update Producerとして稼働中。毎日04:00にシステム・プラグインを更新しHubへ通知。**

**kagutsuchi-sama: 汎用計算サーバーとして稼働。マイクラ鯖の移行を完了。**

**ビルド環境: Arch Linuxホストでaarch64エミュレーションビルドを確立。公式キャッシュの利用によりビルド時間が劇的に短縮。**

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
23. 自動更新システムの構築: 毎日午前4時に `nix flake update`、`nvfetcher` 更新、Git コミット＆プッシュ、`nixos-rebuild switch` を自動実行する Systemd Timer を構築.
24. 自動更新モジュールのリファクタリング: `config.users.users` によるパスの動的解決と、未踏環境での自動クローン（セルフヒーリング）機能を実装。
25. Kagutsuchi-sama 障害復旧と接続性改善: 同じ LAN 内での NAT ループバック問題による VPN 不通を解消するため、`/etc/hosts` によるローカル解決を導入。救出用の一時的な LAN SSH 許可を経て、セキュアな元の状態へ復元。
26. ネットワーク設定の共通化: NAT ループバック対策用のローカル DNS 解決を `common/local-network.nix` にモジュール化し、フラグ一つで有効化できるように改善。
27. 自動更新システムの高度化: `pushChanges` フラグを導入し、更新・プッシュ担当（Producer）と適用担当（Consumer）を分離。また、`nvfetcher` タスクをサービス側から動的に登録する構成にリファクタリングし、ホスト間の移動や拡張性を向上。
28. Nix設定の共通化と集約: `common/nix.nix` を新設し、実験的機能、バイナリキャッシュ、`trusted-users` 設定を一括管理。各ホストからの重複設定を排除。
29. aarch64ビルドの最適化: `torii-chan` のビルドをクロスコンパイルからエミュレーションベースのネイティブビルドに移行。`binfmt` と `extra-platforms` 設定により、x86_64ホスト上で公式のaarch64バイナリキャッシュを利用可能にした。
30. Coordinated Update Hubの完全稼働: `torii-chan` で `update-hub` を稼働させ、ファイアウォール設定（wg0/wg1）を最適化して外部・内部からのステータス確認を可能にした。
31. shosoin-tan Disk ID特定: 実機での `lsblk` により 5 台のディスク ID を特定し、`disko-config.nix` に反映。
32. Legacy BIOS (GRUB) 対応: i7-870 環境での UEFI 非対応を解決するため、BIOS boot パーティション (EF02) の追加と Legacy GRUB 設定への移行を実施。
33. リモートビルド・インストール確立: ターゲット機（shosoin-tan）の負荷軽減のため、ビルドホストで `nixos-system` を構築し `nix copy` で転送してから `nixos-install --system` を実行する高安定性インストール手順を確立。
34. shosoin-tan セットアップ完了: CPU オーバークロック解除による安定化を経て、NixOS のインストールと WireGuard 接続に成功。
35. shosoin-tan ネットワーク安定化: USB-LAN アダプタ環境での不安定さを解消するため、WireGuard MTU を 1380 に設定し、`localNetwork` モジュールによるエンドポイントのローカル解決を導入して起動時の接続を確実に安定させた。
36. タイムゾーンのJST統一: 全ホスト共通設定として `common/time.nix` を導入し、タイムゾーンを `Asia/Tokyo` (JST) に統一。あわせて `chrony` を有効化し、時刻同期の精度と安定性を向上させた。
37. Minecraft サーバー移行: マイクラ関連サービス一式 (Velocity, Lobby, nitac23s) を `kagutsuchi-sama` から `shosoin-tan` へ移行。データの `rsync` 同期、`torii-chan` のポート転送先変更 (10.0.1.4)、および自動更新 Producer 権限の移譲を完了。

### 次のステップ

1.  **共通設定の拡充**: シェルの設定 (zsh/fish) や alias など、全ホストで共通化したい設定を `common/` に追加していく。
2.  **自動更新ログの通知**: 更新失敗時に Discord 等へ通知する仕組みの検討。
3.  **sando-kun 実機インストール**: shosoin-tan で確立したリモートビルド手順を用いて、sando-kun の構築を行う。

### 運用ルール (開発ワークフロー)

- **文書管理**: トップレベルの `README` を整理する際は、ホスト一覧や全体構造などの「プロジェクト俯瞰に必要な共通概要事項」を削除しないこと。詳細はサブディレクトリの `README` に任せつつ、全体像はトップレベルで維持し、各所への誘導を行う。
- 変更後は必ず `nix flake check` を実行し、構文エラーがないか確認する。
- ホスト追加や重要な変更の際は、`GEMINI.md` および `README.md` (日/英) を更新する。
- 変更はこまめに git commit する。

### 主要コマンド

- torii-chan デプロイ: `nixos-rebuild switch --flake .#torii-chan --target-host t3u@10.0.0.1 --use-remote-sudo`
- kagutsuchi-sama デプロイ: `nixos-rebuild switch --flake .#kagutsuchi-sama --target-host t3u@10.0.0.3 --use-remote-sudo`
- shosoin-tan デプロイ: `nixos-rebuild switch --flake .#shosoin-tan --target-host t3u@10.0.0.4 --use-remote-sudo`
- 秘密情報の編集: `nix shell nixpkgs#sops -c sops secrets/secrets.yaml`
