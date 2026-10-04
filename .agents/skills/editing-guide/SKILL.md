---
name: editing-guide
description: パッケージ，モジュール，サービス，プロファイルなどを追加するときに，配置場所と設計原則を確認するために使用する．
---

# 編集ガイド

## パッケージの配置先

- **全ホスト共通のシステムツール**: `nixos/environment/<カテゴリ>.nix` の `environment.systemPackages`．カテゴリ新設時は `nixos/environment/default.nix` に `my.packages.<name>.enable` を定義してから使う．
- **特定ホストだけ**: `hosts/<name>/default.nix` の `environment.systemPackages`．
- **サービス付随のツール**: そのサービスのモジュール内（例: `nixos/services/minecraft/`）．
- **desktop 専用（GUI アプリ等）**: `home/desktop/<カテゴリ>.nix` の `home.packages`（例: theme.nix, gaming.nix）．`home/desktop` は `nixos/profiles/desktop` 経由でのみ読み込まれるため desktop ホストにしか効かない．
- **ユーザー共通ツール**: `home/programs/`（home-manager の `programs.*.enable`．例: cli-tools.nix）．

## モジュール・サービスを追加するとき

1. モジュールを作成し，親の `default.nix` の imports に追加する．
   - 新サービス: `nixos/services/<name>/default.nix` + `nixos/services/default.nix`
   - 新ハードウェア: `nixos/hardware/<name>.nix` + `nixos/hardware/default.nix`
   - desktop 新機能: `home/desktop/<name>.nix` + `home/desktop/default.nix`
2. オプションは `my.*` 体系で定義する（例: `options.my.services.<name>.enable` を `mkEnableOption` で宣言する）．
3. 使うホストの設定で `my.<カテゴリ>.<name>.enable = true;` を指定する．

## 設計原則

- **profiles/*.nix に設定を直書きしない**: プロファイルファイルには options 定義・imports・具体的なシステム設定を書かず，`my.*` オプションを持つモジュールを `nixos/services/`（または `home/desktop/`）に置き，プロファイル側は `enable` フラグ 1 行だけにする．
- **home/ と nixos/ の関心事を分離する**: `home/`（home-manager）はユーザーが使う GUI アプリ・パッケージとユーザー設定，`nixos/`（特に `nixos/services/`）はシステムサービス・`/etc` 設定（`networking.hosts` など）・カーネル連携．両方に及ぶ場合は役割を分ける（例: ランチャー本体は home，hosts ルールは nixos/services）．
- **既存モジュールへの統合を優先する**: 新機能は関連する既存カテゴリに統合する（例: ゲーム関連は `nixos/services/desktop/gaming.nix` や `home/desktop/gaming.nix`）．単独ファイル化は分離しないと維持しづらい大機能のみ．プロファイル側を簡潔に保つためフラグはデフォルト enable にする．

## 新プロファイルを追加するとき

1. `nixos/profiles/<name>/default.nix` を作成し，役割共通の設定を集約する．
2. 使うホストの `flake/hosts.nix` で `profile = "<name>";` を指定する．
