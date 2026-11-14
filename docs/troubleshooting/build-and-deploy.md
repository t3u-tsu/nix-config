# ビルド・デプロイ障害トラブルシューティング

NixOS システムの評価・ビルド・デプロイ時に発生する障害 (メモリ不足，Flake lock 不整合，権限昇格エラー) の原因と復旧手順．

| 障害種別 | エラー兆候 | 影響ホスト | 初動対応 |
| :--- | :--- | :--- | :--- |
| メモリ枯渇 (OOM) | `Killed (signal 9)`, `exit code 137` | `torii-chan` (RAM 1GB), ConoHa VPS (512MB プラン) | 作業機からのリモートビルド (`--build-host localhost`)，または swap の一時拡張 |
| Flake lock 不整合 | `cannot update locked input`, `Git tree is dirty` | 全ホスト | 未追跡ファイルのステージング，単一 input の更新，[flake.lock](../../flake.lock) の復元 |
| 特権昇格失敗 | `pkexec: must be run as root`, `Not authorized` | ヘッドレス機，SSH セッション | 一般ユーザーでの事前ビルドと `sudo`，または `--target-host` によるリモート適用 |

---

## 1. ビルド・評価時のメモリ不足 (OOM)

### 現象

```text
$ nixos-rebuild switch --flake .#torii-chan-hdd
error: builder for '/nix/store/<hash>-<name>.drv' failed with exit code 137

$ dmesg -T | tail -2
[...] Out of memory: Killed process <pid> (nix) total-vm:..., anon-rss:...
[...] oom-killer: gfp_mask=0x..., order=0, oom_score_adj=0
```

`nix build` や `nixos-rebuild` の実行中にプロセスが `Killed` (シグナル 9) で強制終了する．

### 原因

Nix の評価 (モジュールの再帰的マージやオーバーレイ解決) とパッケージのコンパイルは大量のメモリを消費する．`torii-chan` (Orange Pi Zero 3: 物理 RAM 1GB) や ConoHa VPS (512MB プラン) でローカルビルドすると実メモリが枯渇し，Linux カーネルの OOM Killer が発動する．

### 切り分け・復旧手順

#### 対策 1: 作業機からのリモートビルド

リソースに余裕のある作業機 (`BrokenPC`, `x1c7`) でビルドし，生成物を対象機へ転送する．

```bash
# 作業機上でビルドを完了させ，ビルドキャッシュを生成
nix build .#nixosConfigurations.torii-chan-hdd.config.system.build.toplevel --no-link

# ビルドは作業機，適用のみ対象機
nixos-rebuild switch --flake .#torii-chan-hdd \
  --target-host t3u@10.0.0.1 \
  --build-host localhost \
  --sudo --ask-sudo-password \
  --option sandbox false --option filter-syscalls false
```

> [!NOTE]
> Orange Pi Zero 3 (Allwinner H618) のカーネルは `user_namespaces` や `seccomp BPF` に未対応のため，デプロイ時に `--option sandbox false --option filter-syscalls false` の付与が必須である．制約の詳細は [torii-chan ハードウェア仕様](../hardware/orange-pi-zero3.md#52-サンドボックスと-seccomp-bpf-の無効化) を参照する．

#### 対策 2: swap の確保・一時拡張

SBC プロファイル [nixos/profiles/sbc/default.nix](../../nixos/profiles/sbc/default.nix) は 4GB の swapfile (`/var/lib/swapfile`, `vm.swappiness = 10`) を定義する．ディスク移行中などで swap が無効な場合は一時 swap を有効化する．

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

ローカルでビルドする場合は並列ジョブ数とコア数を 1 に制限し，メモリ消費のピークを抑える．

```bash
nixos-rebuild switch --flake .#<hostname> --max-jobs 1 --cores 1
```

---

## 2. Flake lock 不整合・更新エラー

### 現象

```text
error: cannot update locked input '...' because it is locked by another input
error: Git tree '...' is dirty
error: getting status of '...': No such file or directory
```

新規追加した `.nix` ファイルが評価対象に含まれず，`nix flake check` で評価エラーや pre-commit フックの失敗が発生する．

### 原因

| 原因 | 発生メカニズムと影響 |
| :--- | :--- |
| Git 未追跡ファイル | Nix Flakes は Git の index に登録済みのファイルのみを評価するため，新規作成した `.nix` ファイルが未ステージングだと評価に失敗する． |
| `follows` 制約の競合 | [flake.nix](../../flake.nix) で各 input が同一の `nixpkgs` を参照するよう `follows` を設定しているため，上流 flake の更新で互換性が崩れる． |
| 一括更新による不整合 | `nix flake update` で全 input を一括更新すると，nvfetcher 管理ファイル (`_sources/generated.{json,nix}`) とバージョンが齟齬し，不要な大規模リビルドが発生する． |

### 切り分け・復旧手順

#### 対策 1: Git 未追跡ファイルのステージング

```bash
git status
git add -A
```

#### 対策 2: 特定 input の限定的更新

対象の input のみを明示して更新する．`follows` 制約の扱いは [nix-cache-optimization スキル](../../.agents/skills/nix-cache-optimization/SKILL.md) を参照する．

```bash
nix flake update <input-name>
```

#### 対策 3: lockfile の整合性復元

意図しない依存解決の崩壊やキャッシュミスが発生した場合は，Git から直前の lockfile を復元する．

```bash
git checkout flake.lock
```

#### 対策 4: 事前検証

コミット前に flake の評価と検証を実行する．

```bash
git add -A
nix flake check
```

---

## 3. pkexec による特権適用の認証失敗

### 現象

```text
$ pkexec --keep-cwd nixos-rebuild switch --flake .#<hostname>
Cannot run program: No such file or directory
pkexec: must be run as root
Error executing command as another user: Not authorized
```

GUI 認証ダイアログが表示されず，プロンプトが出ないままセッションがタイムアウトする．

### 原因

`pkexec` は Polkit 認証エージェントに依存する．SSH 接続経由，ヘッドレスサーバー (`torii-chan`, `shosoin-tan`, `sando-kun`, `kagutsuchi-sama`)，tmux/screen 内，非 GUI セッションでは Polkit ダイアログを起動できないため認証に失敗する．手動作業では `sudo` を使用する．

### 切り分け・復旧手順

#### 対策 1: 一般ユーザーでの事前ビルド

認証保留時間の長期化とタイムアウトを防ぐため，一般ユーザー権限で事前ビルドを完了させる．手順は [設定変更・適用ワークフロー](../../.agents/skills/dev-workflow/SKILL.md) を参照する．

```bash
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel --no-link
```

#### 対策 2: `sudo` によるローカルフォールバック

Polkit が利用できないローカル端末や SSH セッションでは，`sudo` で直接昇格して実行する．

```bash
# dry-activate で検証後，switch を適用
sudo nixos-rebuild dry-activate --flake .#<hostname>
sudo nixos-rebuild switch --flake .#<hostname>
```

#### 対策 3: `--target-host` によるリモートデプロイ

管理端末からリモートホストへ直接反映する．SBC (`torii-chan`) では対策 1 と同様に `--option sandbox false --option filter-syscalls false` を追加する．

```bash
nixos-rebuild switch --flake .#<hostname> \
  --target-host t3u@10.0.0.<octet> \
  --sudo --ask-sudo-password
```

---

## 関連ドキュメント
- [目次](../README.md) — 全ドキュメントの索引
- [リポジトリ全体アーキテクチャ](../architecture/overview.md) — リポジトリの層構成とモジュール評価フロー
- [日常保守 & ライフサイクル管理](../operations/maintenance.md) — 日次自動更新，ガベージコレクション，定期保守
- [設定変更・適用ワークフロー](../../.agents/skills/dev-workflow/SKILL.md) — dev-workflow スキルによる変更適用手順
- [キャッシュ最適化ガイド](../../.agents/skills/nix-cache-optimization/SKILL.md) — 外部 Flake の follows 制約とビルドキャッシュ最適化
- [torii-chan ハードウェア仕様](../../hosts/torii-chan/README.md) — Orange Pi Zero 3 SBC の構成と制約
