# 作業ログ: Noctalia Shell の follows 先最適化による不整合リスク回避

- 日付: 2026-06-05
- 作業ブランチ: `feature/optimize-noctalia-follows`

## 概要

Niri（Waylandコンポジタ）と Noctalia Shell（デスクトップUIシェル）は機能的に密結合していますが、それぞれの依存する `nixpkgs` リビジョンが異なっていたため、将来のアップデート時に API の不一致によるクラッシュが起きる潜在的リスクがありました。
これを回避するため、`noctalia-shell` の `follows` 先を `niri/nixpkgs` に変更しました。

## 課題と原因

- 変更前、`noctalia-shell` は `nixpkgs-unstable` に `follows` しており、`niri` は `follows` なし（Cachix キャッシュ優先のため独立）となっていました。
- これにより、`niri` が本来ビルドされた `nixpkgs` リビジョンと、`noctalia-shell` がバインドしている `nixpkgs` のリビジョンに乖離が生じる可能性がありました。
- Niri やウェイランドプロトコルの破壊的変更がアップストリームに入った際、リビジョンの乖離によって `noctalia-shell` が `niri` を正常に呼び出せず、起動失敗やセグメンテーションフォールトを引き起こすリスクが存在しました。

## 変更内容

### 1. Flake follows 先の修正 (`flake.nix`)
- `noctalia-shell` の `inputs.nixpkgs.follows` の宛先を `"nixpkgs-unstable"` から `"niri/nixpkgs"`（niri-flake が内部で依存している nixpkgs リビジョン）に変更しました。
- これにより、`noctalia-shell` は常に `niri` と完全に同一のリビジョンの `nixpkgs` を追従してビルド・評価されます。

### 2. GitHub Actions ワークフローの修正 (`.github/workflows/auto-update.yml`)
- `Scheduled Auto Update` ワークフローにおける自動コミットのユーザー設定を変更しました。
  - 変更前: `t3u-daemon / daemon@t3u.uk`
  - 変更後: `github-actions[bot] / github-actions[bot]@users.noreply.github.com`
- これにより、自動アップデートのコミットが GitHub 側で標準の Actions Bot として適切に認識されるようになります。

## 検証方法

1. ロックファイルの更新:
   `nix flake update noctalia-shell`
2. 構文・整合性のチェック:
   `nix flake check`
3. 実機ビルド検証 (ドライ実行):
   `sudo nixos-rebuild dry-activate --flake .#BrokenPC`
