# Minecraft ネットワーク構成

このディレクトリでは、Velocity プロキシと Paper バックエンドサーバーによる Minecraft ネットワークを管理しています。

## 運用状況

- **現在のホスト**: `shosoin-tan` (10.0.1.4)
- **データディレクトリ**: `/srv/minecraft`
- **バックアップ**: 2時間おきに `restic` で実行。
    - ローカル: `/mnt/tank-1tb/backups/minecraft` (ZFSミラー)
    - リモート: `kagutsuchi-sama` (10.0.1.3) の `/mnt/data/backups/shosoin-tan`
- **更新担当 (Producer)**: `shosoin-tan` が毎日 04:00 に本体とプラグインの更新をチェックし、リポジトリを更新します。

## 構成概要

- **プロキシ (Velocity)**: `proxy.nix`
  - ポート: `25565`
  - ドメインベースのルーティング:
    - `mc.t3u.uk` -> `lobby`
    - `nitac23s.mc.t3u.uk` -> `nitac23s`
- **バックエンド (Lobby)**: `servers/lobby.nix`
  - ポート: `25566`
  - 待機ロビー（Voidワールド）。
- **バックエンド (nitac23s)**: `servers/nitac23s.nix`
  - ポート: `25567`
  - メインサバイバルサーバー。

## プラグイン管理 (nvfetcher)

プラグイン（ViaVersion, ViaBackwards）は `plugins/` ディレクトリで **nvfetcher** を使用して管理されています。これにより、最新のハッシュ値を自動取得し、宣言的にプラグインを最新に保つことができます。

- **自動更新**:
  ホスト側で `my.autoUpdate.enable = true` が設定されていれば、毎日午前4時に自動的に `nvfetcher` が実行され、最新のプラグイン情報がリポジトリにプッシュされます。
- **手動更新**:
  ```bash
  (cd services/minecraft/plugins && nvfetcher -c nvfetcher.toml)
  ```

## Lobby サーバーの仕様
- **地形**: Void（一切のブロックがない空気のみのワールド）
- **バイオーム**: `minecraft:the_void`
- **Mob**: 自然スポーン、初期配置ともに完全に無効化 (Peaceful + Spawn Limits 0)
- **モード**: アドベンチャーモード固定
- **構造物**: 生成なし
