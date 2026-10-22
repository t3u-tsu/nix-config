# 日常保守 & ライフサイクル管理

リポジトリの保守運用，日次自動更新，ディスク容量管理 (ガベージコレクション)，およびカーネル更新手順．

## 1. 自動更新パイプライン (`auto-update.yml`)

GitHub Actions のスケジュールワークフローが毎日日本時間 04:00 に自動実行される．処理の流れ:

1. `nvfetcher` を実行し，[nvfetcher.toml](../../nvfetcher.toml) に定義された最新パッケージのコミット・ハッシュ値と [_sources/generated.nix](../../_sources/generated.nix) を更新する．
2. `nix flake update` で [flake.lock](../../flake.lock) の依存 Flake 入力を最新に更新する．
3. 全ホストの評価と pre-commit hooks (`nix flake check`) を実行して CI 検証を行う．
4. すべての検証に成功した場合のみ，コミットを作成して `main` ブランチへ自動プッシュする．

### 手動での更新実行
開発環境 (`nix develop` または direnv) 下で，ローカルのパッケージやロックファイルを先行して更新する場合:
```bash
# nvfetcher パッケージの更新
nvfetcher

# flake inputs の更新
nix flake update

# 変更の検証
nix flake check
```

---

## 2. ディスク容量管理とガベージコレクション

全ホスト共通設定 ([nixos/base/nix.nix](../../nixos/base/nix.nix)) で週次の 14 日経過自動 GC (`gc.automatic = true; dates = "weekly"; options = "--delete-older-than 14d";`) およびビルド時ストア最適化 (`auto-optimise-store = true;`) が稼働している．

ディスク容量逼迫時や即時クリーンアップが必要な場合は，以下のコマンドを実行する．

### 不要世代削除とストア掃除
```bash
# 14日以上前の古い世代を手動で削除 (システム世代およびユーザープロファイル)
sudo nix-collect-garbage --delete-older-than 14d
nix-collect-garbage --delete-older-than 14d

# ハードリンクによる重複ブロックの手動最適化
sudo nix-store --optimise
```

### 低容量マシン (SBC / ラップトップ) での緊急回収
```bash
# 現在の世代を除く全世代を一括破棄 (システムおよびユーザー)
sudo nix-collect-garbage -d
nix-collect-garbage -d
sudo /run/current-system/bin/switch-to-configuration boot
```

---

## 3. カーネル更新と再起動

Linux カーネルの更新適用には OS の再起動が必要となる．

### Step 1: 事前ビルドと更新確認
特権昇格プロセスの実行時間を最小化するため，事前に一般ユーザー権限でビルドを完了させ，ドライランでカーネル更新等の有無を確認する．
```bash
# 事前ビルド (必須)
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel --no-link

# ドライランでカーネル更新の有無を確認
nixos-rebuild dry-build --flake .#<hostname>
```

### Step 2: 設定適用と再起動
`dev-workflow` に準拠し，デスクトップ環境では `pkexec`，ヘッドレス機では `sudo` を用いて設定を適用する．
```bash
# デスクトップ環境 (Polkit GUI 認証)
pkexec --keep-cwd nixos-rebuild switch --flake .#<hostname>

# ヘッドレス機 / SSH 経由 (sudo)
sudo nixos-rebuild switch --flake .#<hostname>

# リモート機 (再起動前に boot エントリを更新)
nixos-rebuild boot --flake .#<hostname> --target-host t3u@10.0.0.X --sudo --ask-sudo-password
ssh t3u@10.0.0.X "sudo reboot"
```

### Step 3: 起動失敗時のロールバック
カーネルの非互換性等で起動に失敗した場合は，ブートローダ (GRUB または extlinux) の世代選択画面で直前の正常世代を選択して起動する (詳細は [../troubleshooting/emergency-recovery.md](../troubleshooting/emergency-recovery.md) 参照)．

---

## 関連ドキュメント
- [目次 (設計・運用ドキュメント)](../README.md) — 設計・運用ドキュメント一覧
- [リポジトリ全体アーキテクチャ](../architecture/overview.md) — リポジトリの全体構成と設計方針
- [Flake とモジュール設計原則](../architecture/flake-and-modules.md) — Flake 出力構造とモジュール分離原則
- [トラブルシューティング: ビルド・デプロイ](../troubleshooting/build-and-deploy.md) — ビルド・評価・構文エラーの対処手順
- [トラブルシューティング: 緊急時復旧](../troubleshooting/emergency-recovery.md) — 起動不能・システム障害時のロールバック・復旧手順
