---
name: editing-guide
description: パッケージ，モジュール，サービス，プロファイルなどを追加するときに，配置場所と設計原則を確認するために使用する．
---

# 編集ガイド（パッケージ・モジュールを追加するとき）

## パッケージを追加するとき

- **全ホスト共通のシステムツール**: `nixos/environment/<カテゴリ>.nix` の `environment.systemPackages` に追記する．カテゴリ新設は `nixos/environment/default.nix` に `my.packages.<name>.enable` を定義してから使う．
- **特定ホストだけ**: `hosts/<name>/default.nix` で `environment.systemPackages` を直接追記する．
- **サービスに付随するツール**: そのサービスのモジュール内に追記する（例: `nixos/services/minecraft/` 配下）．
- **desktop 専用（GUI アプリ等）**: `home/desktop/<カテゴリ>.nix` の `home.packages` に追記する（例: theme.nix, gaming.nix）．`home/desktop` は `nixos/profiles/desktop` 経由でのみ読み込まれるため，desktop ホストにしか影響しない．
- **ユーザー共通ツール**: `home/programs/` 配下（home-manager の `programs.*.enable` パターン．例: cli-tools.nix）．

## モジュール・サービスを追加するとき

1. 対応ディレクトリにモジュールを作成し，親の `default.nix` の imports に追加する．
   - 新サービス: `nixos/services/<name>/default.nix` + `nixos/services/default.nix`
   - 新ハードウェア: `nixos/hardware/<name>.nix` + `nixos/hardware/default.nix`
   - desktop 新機能: `home/desktop/<name>.nix` + `home/desktop/default.nix`
2. オプションは `my.*` 体系で定義する（例: `options.my.services.<name>.enable` を宣言し，`mkEnableOption` でフラグ化）．
3. 使いたいホストの設定で `my.<カテゴリ>.<name>.enable = true;` を指定する．

## 設計原則

- **profiles/*.nix に設定を直書きしない**: プロファイルファイル（例: `nixos/profiles/desktop/default.nix`）には options 定義・imports・具体的なシステム設定を書かず，`my.*` オプションを持つモジュールを `nixos/services/`（または `home/desktop/`）に作成し，プロファイル側は `enable` フラグ（1行）のみ記述する．
- **home/ と nixos/ の関心事を分離する**:
  - `home/`（home-manager，特に `home/desktop`）: ユーザーが使う GUI アプリ・パッケージ（`home.packages`）とユーザー設定
  - `nixos/`（特に `nixos/services/`）: システムサービス，`/etc` 設定（`networking.hosts` など），カーネル・システム連携
  - 判断基準: 「ユーザーが直接使うデスクトップアプリ」なら home 側，「`/etc` へ書くなどシステム全体に効く設定を含む」なら nixos 側に置く．両方に及ぶ場合は home（アプリ）と nixos（hosts 等のシステム要件）に役割を分ける（例: ランチャー本体は home，hosts ルールは nixos/services）．
- **既存モジュールへの統合を優先する**: 新機能は関連する既存モジュールカテゴリに統合する（例: ゲーム関連は `nixos/services/desktop/gaming.nix` や `home/desktop/gaming.nix`）．単独ファイル化は機能が大きく，既存と分離しないと維持しづらい場合のみ．フラグはデフォルト enable にするなどしてプロファイル側の記述を簡潔に保つ．

## 新プロファイルを追加するとき

1. `nixos/profiles/<name>/default.nix` を作成し，役割共通の設定を集約する．
2. 使うホストの `flake/hosts.nix` で `profile = "<name>";` を指定する．
