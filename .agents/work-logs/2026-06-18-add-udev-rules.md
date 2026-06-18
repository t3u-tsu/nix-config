# 作業ログ: WCH-LinkE 書き込み用 udev ルールの追加

- 日付: 2026-06-18
- 作業ブランチ: `feature/add-udev-rules`

## 概要

WCH-LinkE プログラマ等のハードウェア開発機器に対して一般ユーザー権限でファームウェアの書き込み・デバッグ（フラッシュ）が行えるよう、NixOS システム層の udev ルールを設定しました。このルールは、desktop プロファイルの `dev-tools.hardware.enable` に連動して有効化されます。

## 課題と原因

ch32fun などを利用したマイコン開発（WCH-LinkE 経由）において、デフォルトでは Linux システム側の USB アクセス制限（一般ユーザー権限不足）によりフラッシュの書き込み時に権限エラーが発生していました。これを回避するためには udev ルールによるデバイスパーミッションの解放が必要でした。

## 変更内容

### 1. システム層 udev ルールの追加 (`modules/profiles/desktop/default.nix`)
- WCH-LinkE（RISC-Vモード: `1a86:8010`、ARMモード: `1a86:8012`）向けの udev ルールを `services.udev.extraRules` に追加しました。
- Home Manager 側の `my.home.desktop.dev-tools.hardware.enable` が有効な場合のみ、この udev ルールが適用されるよう `lib.mkIf` を用いて連動させました。
- デバイスは `dialout` グループに割り当てられ、`MODE="0660"` でアクセス可能になります（一般ユーザーはすでに `dialout` に所属しているため権限が与えられます）。

### 2. ドキュメントの更新
- `modules/home/desktop/dev-tools/README.md` および `README.ja.md` に、`hardware.nix` に関する記述を追加し、udev ルールが統合されている旨を追記しました。

## 検証方法

1. 構文・評価チェック:
   `nix flake check` (成功)
