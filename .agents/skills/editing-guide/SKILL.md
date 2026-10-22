---
name: editing-guide
description: パッケージ，モジュール，サービス，プロファイル追加時の配置先と設計原則．
---

# 編集ガイド

## パッケージの配置先

| 区分 | 配置先 | 備考 |
| :--- | :--- | :--- |
| 全ホスト共通システムツール | `nixos/environment/<カテゴリ>.nix` の `environment.systemPackages` | カテゴリ新設時は [nixos/environment/default.nix](../../../nixos/environment/default.nix) に `my.packages.<name>.enable` を定義 |
| 特定ホスト専用ツール | `hosts/<name>/default.nix` の `environment.systemPackages` | 特定マシンでのみ必要なツール |
| サービス付随ツール | 各サービスモジュール内（例: `nixos/services/minecraft/`） | 当該サービスの稼働に必要なツール |
| デスクトップ専用（GUI アプリ等） | `home/desktop/<カテゴリ>.nix` の `home.packages` | `nixos/profiles/desktop` 経由で desktop ホストにのみ適用 |
| ユーザー共通ツール | `home/programs/`（Home Manager の `programs.*.enable`） | シェルや CLI ツールなどのユーザー環境設定 |

## モジュール・サービスを追加するとき

1. モジュールを作成し，親の `default.nix` の imports に追加する:
   - 新サービス: `nixos/services/<name>/default.nix` + [nixos/services/default.nix](../../../nixos/services/default.nix)
   - 新ハードウェア: `nixos/hardware/<name>.nix` + [nixos/hardware/default.nix](../../../nixos/hardware/default.nix)
   - デスクトップ新機能: `home/desktop/<name>.nix` + [home/desktop/default.nix](../../../home/desktop/default.nix)
2. オプションは `my.*` 体系で定義する（例: `options.my.services.<name>.enable` を `mkEnableOption` で宣言する）．
3. 使うホストの設定で `my.<カテゴリ>.<name>.enable = true;` を指定する．

## 設計原則

- プロファイル（`profiles/*.nix`）に具象設定を直書きせず，`my.*` オプションを持つモジュールを `nixos/services/`（または `home/desktop/`）に配置し，プロファイル側は `enable` フラグの指定にとどめる．
- `home/`（Home Manager）と `nixos/` の関心事を明確に分離する．`home/` はユーザー環境の GUI アプリ・ツールやユーザー設定，`nixos/`（特に `nixos/services/`）はシステムサービス・`/etc` 設定（`networking.hosts` 等）・カーネル連携を定義する（双方にまたがる場合はランチャー本体を home，hosts ルールを nixos/services に置くなど役割を分担する）．
- 新機能は既存の関連カテゴリ（例: ゲーム関連なら [nixos/services/desktop/gaming.nix](../../../nixos/services/desktop/gaming.nix) や [home/desktop/gaming.nix](../../../home/desktop/gaming.nix)）への統合を優先し，単独ファイルの新設は独立管理すべき大規模機能に限定する．
- 新規スクリプト（`scripts/` や運用ツール等）は `ysh` スキルに従い原則として YSH（`.ysh`）で作成し，ネイティブ JSON やデータ構造を活用して `jq` や文字列操作ハックを排除する（インストーラ ISO やレスキュー環境等の最小構成向けのみ例外）．Nix 内のスクリプト生成には `pkgs.writeYshApplication`（`runtimeInputs` による PATH 注入対応）や `pkgs.writeYsh` / `pkgs.writeYshBin` を使用する（ビルド時に `ysh -n` で構文検証が行われる）．

## 新プロファイルを追加するとき

1. `nixos/profiles/<name>/default.nix` を作成し，役割共通の設定を集約する．
2. 使うホストの [flake/hosts.nix](../../../flake/hosts.nix) で `profile = "<name>";` を指定する．
