# バックアップシステム (Restic)

このディレクトリでは、Restic を使用したシステム全体のバックアップ構成を管理しています。

## 構成概要

- **送信側モジュール (`default.nix`)**: 
  各ホストで `my.backup` オプションを有効にすることで、ローカルおよびリモートへのバックアップを自動化します。
- **受信側モジュール (`receiver.nix`)**: 
  バックアップデータを受け入れるサーバー（現在は `kagutsuchi-sama`）側の設定です。専用ユーザーと SFTP 制限が含まれます。

## 運用ルール

### バックアップ先
1.  **Local**: 各マシンの信頼性の高いディスク（例：shosoin-tan の ZFS Mirror）。
2.  **Remote**: `kagutsuchi-sama` (10.0.1.3) の大容量 HDD。

### 世代保持ポリシー
- 直近 7 日分
- 過去 4 週間分
- 過去 6 ヶ月分
(これより古いものは自動的に削除されます)

## 運用コマンド

### 状態確認
```bash
# ローカルバックアップの状況
sudo systemctl status restic-backups-local-backup.service
# リモートバックアップの状況
sudo systemctl status restic-backups-remote-backup.service
```

### 手動実行
```bash
sudo systemctl start restic-backups-remote-backup.service
```

### スナップショットの一覧表示
```bash
# ローカルの場合
sudo restic -r /mnt/tank-1tb/backups/minecraft snapshots
# リモートの場合（SSH設定が必要）
sudo restic -r sftp:restic-shosoin@10.0.1.3:/mnt/data/backups/shosoin-tan snapshots
```

## 復元手順

1.  復元したいスナップショットの ID を上記コマンドで確認します。
2.  以下のコマンドを実行して復元します：
    ```bash
    sudo restic -r <リポジトリパス> restore <ID> --target /path/to/restore
    ```

## 注意事項
- リモート接続には `programs.ssh.extraConfig` による鍵の指定が必要です。
- サーバー側 (`receiver.nix`) ではセキュリティのため SFTP 以外の操作が禁止されています。
