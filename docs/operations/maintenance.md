# 日常保守 & ライフサイクル管理

リポジトリの保守運用，日次自動更新，ディスク容量管理 (ガベージコレクション)，およびカーネル更新手順．

## 1. 前提条件

| 項目 | 要件・確認事項 |
| :--- | :--- |
| 対象ホスト | 全ホスト (自動更新は GitHub Actions，GC とカーネル更新は各ホスト) |
| 実行権限 | 一般ユーザー (`nix build`, `just build`, `just gc`) と root (`sudo`, `pkexec`) |
| 必要ツール | `git`, `nix`, `just`, `nh`, `nvfetcher`, `gh` (CI 実行結果の確認) |

### 1.1 作業前チェックリスト

- [ ] 適用対象ホストの構成名 (`<hostname>`) を確認している．
- [ ] 更新対象の変更内容を `just diff` または `nixos-rebuild dry-build` で確認している．
- [ ] リモート機を更新する場合は，再起動後も接続できる経路 (Nebula または Cloudflare Tunnel) を確保している．

---

## 2. 作業手順

### Step 1: 自動更新パイプラインの確認

GitHub Actions のスケジュールワークフロー ([.github/workflows/auto-update.yml](../../.github/workflows/auto-update.yml)) が毎日日本時間 04:00 に自動実行される．処理の流れ:

1. `nvfetcher` を実行し，[nvfetcher.toml](../../nvfetcher.toml) に定義された最新パッケージのコミット・ハッシュ値と [_sources/generated.nix](../../_sources/generated.nix) を更新する．
2. `nix flake update` で [flake.lock](../../flake.lock) の依存 Flake 入力を最新に更新する．
3. 全ホストの評価と pre-commit hooks (`nix flake check`) を実行して CI 検証する．
4. すべての検証に成功した場合のみ，コミットを作成して `main` ブランチへ自動プッシュする．

```bash
gh run list --workflow=auto-update.yml --limit 3
```

### Step 2: 手動での依存更新

開発環境 (`nix develop` または direnv) 下で，ローカルのパッケージやロックファイルを先行して更新する．

```bash
# nvfetcher パッケージの更新 (just update nvfetcher と等価)
nvfetcher

# flake inputs の更新 (just update flake と等価)
nix flake update

# 変更の検証
nix flake check
```

特定の入力やパッケージのみを更新する場合は recipe に引数を渡す．

```bash
just update flake nixpkgs
just update nvfetcher
```

### Step 3: ガベージコレクションとストア最適化

全ホスト共通設定 ([nixos/base/nix.nix](../../nixos/base/nix.nix)) で週次の 14 日経過自動 GC (`gc.automatic = true; dates = "weekly"; options = "--delete-older-than 14d";`) およびビルド時ストア最適化 (`auto-optimise-store = true;`) が稼働している．ディスク容量逼迫時や即時クリーンアップが必要な場合は次を実行する．

```bash
# 14日以上前の古い世代を手動で削除 (システム世代およびユーザープロファイル)
sudo nix-collect-garbage --delete-older-than 14d
nix-collect-garbage --delete-older-than 14d

# nh 経由で各プロファイルの古い世代を削除 (既定は最新 1 世代を保持)
just gc

# 保持期間を揃えて削除する場合
just gc --keep-since 14d

# ハードリンクによる重複ブロックの手動最適化
sudo nix-store --optimise
```

### Step 4: 低容量マシンでの緊急回収

SBC やラップトップで容量が逼迫した場合は，現行世代を除く全世代を破棄する．

```bash
# 現在の世代を除く全世代を一括破棄 (システムおよびユーザー)
sudo nix-collect-garbage -d
nix-collect-garbage -d
sudo /run/current-system/bin/switch-to-configuration boot
```

### Step 5: カーネル更新の事前ビルドと差分確認

Linux カーネルの更新適用には OS の再起動が必要となる．特権昇格プロセスの実行時間を最小化するため，事前に一般ユーザー権限でビルドを完了させ，ドライランでカーネル更新等の有無を確認する．

```bash
# 事前ビルド (必須)
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel --no-link

# ドライランでカーネル更新の有無を確認
nixos-rebuild dry-build --flake .#<hostname>

# nh 経由の同等操作 (just build / just diff)
just build
just diff
```

### Step 6: 設定適用と再起動

`dev-workflow` に準拠し，デスクトップ環境では `pkexec`，ヘッドレス機では `sudo` を用いて設定を適用する (`just switch` / `just boot` は内部で `nh` を呼ぶ)．

```bash
# デスクトップ環境 (Polkit GUI 認証)
pkexec --keep-cwd nixos-rebuild switch --flake .#<hostname>

# ヘッドレス機 / SSH 経由 (sudo)
sudo nixos-rebuild switch --flake .#<hostname>

# リモート機 (再起動前に boot エントリを更新)
nixos-rebuild boot --flake .#<hostname> --target-host t3u@10.0.0.X --sudo --ask-sudo-password
ssh t3u@10.0.0.X "sudo reboot"
```

### Step 7: 起動失敗時のロールバック

カーネルの非互換性等で起動に失敗した場合は，ブートローダ (GRUB または extlinux) の世代選択画面で直前の正常世代を選択して起動する．詳細は [緊急時復旧](../troubleshooting/emergency-recovery.md) を参照する．

---

## 3. 事後検証

### 3.1 自動更新の実行結果

```bash
gh run list --workflow=auto-update.yml --limit 1 --json status,conclusion
```

期待出力:
```json
[{"conclusion":"success","status":"completed"}]
```

### 3.2 稼働中のカーネル

```bash
uname -r
systemctl is-system-running
```

期待出力:
```text
running
```

`uname -r` の値が Step 5 の `nixos-rebuild dry-build` が表示したカーネルバージョンと一致することを確認する．カーネルはホストごとに `pkgs.linuxPackages` または `pkgs.linuxPackages_xanmod` を選択する ([nixos/profiles/tower-server/boot.nix](../../nixos/profiles/tower-server/boot.nix), [hosts/x1c7/default.nix](../../hosts/x1c7/default.nix))．

### 3.3 ディスク使用量と世代数

```bash
df -h /nix
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -3
```

期待出力:
```text
Filesystem      Size  Used Avail Use% Mounted on
```

`Use%` 列が 90% 未満であり，世代一覧の末尾が `(current)` の付いた現行世代であることを確認する．

---

## 関連ドキュメント
- [目次 (設計・運用ドキュメント)](../README.md) — 設計・運用ドキュメント一覧
- [リポジトリ全体アーキテクチャ](../architecture/overview.md) — リポジトリの全体構成と設計方針
- [Flake とモジュール設計原則](../architecture/flake-and-modules.md) — Flake 出力構造とモジュール分離原則
- [トラブルシューティング: ビルド・デプロイ](../troubleshooting/build-and-deploy.md) — ビルド・評価・構文エラーの対処手順
- [トラブルシューティング: 緊急時復旧](../troubleshooting/emergency-recovery.md) — 起動不能・システム障害時のロールバック・復旧手順
