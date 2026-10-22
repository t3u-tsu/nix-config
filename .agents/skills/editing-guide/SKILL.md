---
name: editing-guide
description: パッケージ，モジュール，サービス，プロファイル追加時の配置先と設計原則．
---

# 編集ガイド

## パッケージの配置先

- **全ホスト共通のシステムツール**: `nixos/environment/<カテゴリ>.nix` の `environment.systemPackages`．カテゴリ新設時は `nixos/environment/default.nix` に `my.packages.<name>.enable` を定義してから使う．
- **特定ホスト専用ツール**: `hosts/<name>/default.nix` の `environment.systemPackages`．
- **サービス付随のツール**: そのサービスのモジュール内（例: `nixos/services/minecraft/`）．
- **デスクトップ専用（GUI アプリ等）**: `home/desktop/<カテゴリ>.nix` の `home.packages`（例: theme.nix, gaming.nix）．`home/desktop` は `nixos/profiles/desktop` 経由でのみ読み込まれるため desktop ホストにのみ適用される．
- **ユーザー共通ツール**: `home/programs/`（Home Manager の `programs.*.enable`．例: cli-tools.nix）．

## モジュール・サービスを追加するとき

1. モジュールを作成し，親の `default.nix` の imports に追加する．
   - 新サービス: `nixos/services/<name>/default.nix` + `nixos/services/default.nix`
   - 新ハードウェア: `nixos/hardware/<name>.nix` + `nixos/hardware/default.nix`
   - デスクトップ新機能: `home/desktop/<name>.nix` + `home/desktop/default.nix`
2. オプションは `my.*` 体系で定義する（例: `options.my.services.<name>.enable` を `mkEnableOption` で宣言する）．
3. 使うホストの設定で `my.<カテゴリ>.<name>.enable = true;` を指定する．

## 設計原則

- **profiles/*.nix に具象設定を直書きしない**: プロファイルには options 定義や具体的な設定を書かず，`my.*` オプションを持つモジュールを `nixos/services/`（または `home/desktop/`）に配置し，プロファイル側は `enable` フラグの指定にとどめる．
- **home/ と nixos/ の関心事を分離する**: `home/`（Home Manager）はユーザー環境の GUI アプリ・ツールやユーザー設定，`nixos/`（特に `nixos/services/`）はシステムサービス・`/etc` 設定（`networking.hosts` など）・カーネル連携を定義する．双方にまたがる場合は役割を明確に分担する（例: ランチャー本体は home，hosts ルールは nixos/services）．
- **既存モジュールへの統合を優先する**: 新機能は既存の関連カテゴリへ統合する（例: ゲーム関連は `nixos/services/desktop/gaming.nix` や `home/desktop/gaming.nix`）．単独ファイルの新設は，独立管理すべき大規模機能に限定する．
- **スクリプトは YSH を標準とする**: 新規スクリプト（`scripts/` や運用ツール等）は原則として `ysh` スキルに従い YSH（`.ysh`）で作成し，ネイティブ JSON やデータ構造を用いて `jq` や文字列操作ハックを排除する（インストーラ ISO やレスキュー環境等の最小構成向けのみ例外）．Nix 内のスクリプト生成には `pkgs.writeYshApplication`（`runtimeInputs` による PATH 注入対応）や `pkgs.writeYsh` / `pkgs.writeYshBin` を使用する．ビルド時に `ysh -n` による構文検証が行われる．

## 新プロファイルを追加するとき

1. `nixos/profiles/<name>/default.nix` を作成し，役割共通の設定を集約する．
2. 使うホストの `flake/hosts.nix` で `profile = "<name>";` を指定する．
