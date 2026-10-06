# ビルド・デプロイ障害トラブルシューティング

本ドキュメントは，NixOS システムの評価・ビルド・デプロイ段階で発生する代表的な障害（メモリ不足，Flake lock 不整合，権限昇格エラー）の原因と復旧手順を記述する．

---

## 1. ビルド・評価時のメモリ不足 (OOM) 対策

### 現象・エラーメッセージ
- `nix build` や `nixos-rebuild` の実行中に突然プロセスが `Killed`（シグナル 9）で強制終了する．
- `dmesg -T` に `Out of memory: Killed process ... (nix)` や `oom-killer` のログが記録される．
- ターミナルに `error: builder for '...' failed with exit code 137` が出力される．

### 原因
Nix の評価（モジュールの再帰的マージやオーバーレイ解決）およびパッケージのコンパイルは大量のメモリを消費する．特に `torii-chan`（Orange Pi Zero 3: 物理 RAM 1GB）や ConoHa VPS（512MB プラン）などの低スペック機上でローカルビルドを実行した場合，実メモリが枯渇して Linux カーネルの OOM Killer が発動する．

### 切り分け・復旧手順

#### 対策 1: リモートビルド / 作業機からのデプロイ（推奨）
低スペック機ローカルでのビルドを避け，十分なリソースを持つ作業機（`BrokenPC` や `x1c7`）からビルドおよび転送を行う．

```bash
# 1. 事前ビルド（作業機上でビルドを完了させ，ビルドキャッシュを生成）
nix build .#nixosConfigurations.torii-chan-hdd.config.system.build.toplevel --no-link

# 2. リモートデプロイ（ビルドは作業機，適用のみターゲット機）
nixos-rebuild switch --flake .#torii-chan-hdd \
  --target-host t3u@10.0.0.1 \
  --build-host localhost \
  --sudo --ask-sudo-password \
  --option sandbox false --option filter-syscalls false
```
> [!NOTE]
> Orange Pi Zero 3（Allwinner H618）のカーネルは `user_namespaces` や `seccomp BPF` に未対応のため，デプロイ時に `--option sandbox false --option filter-syscalls false` の付与が必須である（詳細は [`hosts/torii-chan/README.md`](../../hosts/torii-chan/README.md) 参照）．

#### 対策 2: Swap の確保・一時拡張
SBC プロファイル（[`nixos/profiles/sbc/default.nix`](../../nixos/profiles/sbc/default.nix)）では 4GB の swapfile（`/var/lib/swapfile`，`vm.swappiness = 10`）が標準定義されている．ディスク移行作業中や swap が無効化されている場合は，手動で一時 swap を有効化する:

```bash
# 一時 swapfile (4GB) の作成と有効化
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# swap 認識確認
swapon --show
```

#### 対策 3: Nix の並列実行制限
ローカルでビルドせざるを得ない場合，並列ジョブ数とコア数を 1 に制限してメモリ消費のピークを抑制する:

```bash
nixos-rebuild switch --flake .#<hostname> --max-jobs 1 --cores 1
```

---

## 2. Flake lock 不整合・更新エラー

### 現象・エラーメッセージ
- `error: cannot update locked input '...' because it is locked by another input`
- `error: Git tree '...' is dirty`
- `error: getting status of '...': No such file or directory`（新規追加ファイルが参照できない）
- `nix flake check` で pre-commit フックや評価エラーが発生する．

### 原因
1. **Git 未追跡ファイル**: Nix Flakes は Git の index に登録されているファイルのみを評価対象とするため，新規作成した `.nix` ファイルが未ステージングの場合に評価失敗となる．
2. **`follows` 制約の競合**: `flake.nix` 内で各 input が同一の `nixpkgs` を参照するよう `follows` を設定している際，上流 flake の更新によって互換性が崩れる．
3. **一括更新による不整合**: `nix flake update` で全 input を一括更新した結果，nvfetcher 管理ファイル（`_sources/generated.{json,nix}`）とのバージョン齟齬や不要な大規模リビルドが発生する．

### 切り分け・復旧手順

#### 手順 1: Git 未追跡ファイルのステージング
```bash
git status
# 新規ファイルや変更ファイルを Git のインデックスに追加
git add -A
```

#### 手順 2: 特定 input の限定的更新
全 input を一括更新せず，対象の input のみを明示して更新する（[`nix-cache-optimization` スキル](../../.agents/skills/nix-cache-optimization/SKILL.md) 参照）:

```bash
# 特定の input のみ更新
nix flake lock --update-input <input-name>
```

#### 手順 3: lockfile の整合性復元
意図しない依存解決の崩壊やキャッシュミスが発生した場合は，Git から直前の lockfile を復元する:

```bash
git checkout flake.lock
```

#### 手順 4: 事前検証
コミット前に必ず flake の評価と検証を実行する:

```bash
nix flake check
```

---

## 3. pkexec 認証失敗時のフォールバック

### 現象・エラーメッセージ
- `pkexec --keep-cwd nixos-rebuild switch --flake .#<hostname>` を実行した際，GUI 認証ダイアログが表示されずエラーとなる:
  - `Cannot run program: No such file or directory`
  - `pkexec: must be run as root`
  - `Error executing command as another user: Not authorized`
  - プロンプトが表示されずセッションがタイムアウトする．

### 原因
`pkexec` はデスクトップ環境で常駐する Polkit 認証エージェントに依存する．SSH 接続経由，ヘッドレスサーバー（`torii-chan`, `shosoin-tan`, `sando-kun`, `kagutsuchi-sama`），tmux/screen 内，あるいは非 GUI セッションでは Polkit ダイアログを起動できないため認証に失敗する．

### 切り分け・フォールバック手順

#### Step 1: 事前ビルド（必須）
認証保留時間の長期化やタイムアウトを防ぐため，必ず一般ユーザー権限で事前ビルドを完了させる（[`GEMINI.md`](../../GEMINI.md) 運用ルール）:

```bash
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel --no-link
```

#### Step 2: `sudo` によるローカルフォールバック
Polkit が利用できないローカル端末や SSH セッションでは，`sudo` を用いて直接昇格して実行する:

```bash
# dry-activate で検証後，switch を適用
sudo nixos-rebuild dry-activate --flake .#<hostname>
sudo nixos-rebuild switch --flake .#<hostname>
```

#### Step 3: リモートデプロイ（`--target-host`）
管理端末からリモートホストへ直接反映する場合は `--target-host` を使用する:

```bash
# 一般サーバー向け
nixos-rebuild switch --flake .#<hostname> \
  --target-host t3u@10.0.0.<octet> \
  --sudo --ask-sudo-password

# SBC (torii-chan) 向け
nixos-rebuild switch --flake .#torii-chan-hdd \
  --target-host t3u@10.0.0.1 \
  --sudo --ask-sudo-password \
  --option sandbox false --option filter-syscalls false
```

---

## 関連ドキュメント
- [リポジトリ全体アーキテクチャ](../architecture/overview.md)
- [定期保守・自動更新](../operations/maintenance.md)
- [設定変更・適用ワークフロー](../../.agents/skills/dev-workflow/SKILL.md)
- [キャッシュ最適化ガイド](../../.agents/skills/nix-cache-optimization/SKILL.md)
- [torii-chan ハードウェア仕様](../../hosts/torii-chan/README.md)
