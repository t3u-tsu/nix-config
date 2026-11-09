---
name: coding-worker
description: >-
  Delegate implementation, refactoring, and technical review tasks to external coding workers (pi, dsh, codewhale) via scripts/run.ysh.
  Use when the user asks to use external workers or delegate coding/review tasks.
---

# Coding Worker

[scripts/run.ysh](scripts/run.ysh) を用いて外部コーディングワーカー (`pi`, `dsh`, `codewhale`)にコード実装・リファクタリング・技術レビューを委譲する手順．複数の独立タスクを並列ディスパッチする際の分割・設計原則は `dispatching-parallel-agents` スキル (`~/.agents/skills/dispatching-parallel-agents/`)を参照．

## 基本使用方法

```bash
# 実装・リファクタリング
.agents/skills/coding-worker/scripts/run.ysh "<PROMPT_IN_ENGLISH>"

# 改善差分を直接作成させる技術レビュー
.agents/skills/coding-worker/scripts/run.ysh "Review the diff origin/main..HEAD for technical correctness and apply necessary improvements."

# 読み取り専用レビュー (ワーキングツリーを変更しない)
.agents/skills/coding-worker/scripts/run.ysh --read-only "Review the diff origin/main..HEAD for technical correctness."

# セッション継続 (直前セッション，または特定 TASK_ID セッション)
CONTINUE=1 .agents/skills/coding-worker/scripts/run.ysh "<FOLLOW_UP_PROMPT>"
CONTINUE=1 TASK_ID="feat-dns" .agents/skills/coding-worker/scripts/run.ysh "<FOLLOW_UP_PROMPT>"
```

ワークツリー内で実行する場合や複数ワーカーを並列起動する場合は，単一の作業ワークツリー上で対象ファイルを排他指定し，`TASK_ID` を分けて実行する (`run_command` では `WaitMsBeforeAsync: 500` を指定して同一ターン内で同時発行する):

```bash
cd .worktrees/<topic>/main && TASK_ID="worker-a" /home/t3u/nix-config/.agents/skills/coding-worker/scripts/run.ysh "<PROMPT_A>"
cd .worktrees/<topic>/main && TASK_ID="worker-b" /home/t3u/nix-config/.agents/skills/coding-worker/scripts/run.ysh "<PROMPT_B>"
```

## オプションと環境変数

- `--read-only` (または `READ_ONLY=1`):
  ワーキングツリーの変更を禁止する読み取り専用モード (`worker=pi` 専用)．書き込み系ツールを無効化し，実行前後の Git フィンガープリントを照合して変更が検知された場合は終了コード `3` で失敗する．

| 変数 | デフォルト | 説明 |
| :--- | :--- | :--- |
| `WORKER` | `pi` | 使用するワーカーバックエンド (`pi`, `dsh`, `codewhale`)． |
| `TASK_ID` | (空) | タスク識別子を指定してセッションを個別に保存・管理する (例: `feat-dns`)． |
| `CONTINUE` | `0` | `1` でセッションを継続する (`TASK_ID` 併用時はそのタスク，未指定時は直前セッション)． |
| `READ_ONLY` | `0` | `1` で `--read-only` モードを有効化する (`worker=pi` 専用)． |
| `EXTRA_FLAGS` | (空) | ワーカー実行バイナリへ追加で渡す任意フラグ． |

### 終了コード

| 終了コード | 意味 |
| :--- | :--- |
| `0` | 正常終了． |
| `1` | 引数不正，再帰呼び出し制限超過 (`__CODING_WORKER_DEPTH >= 2`)，または非対応ワーカーでの `--read-only` 指定． |
| `2` (またはワーカー固有) | ワーカープロセスの異常終了． |
| `3` | `--read-only` 実行中にワーキングツリーの変更を検知． |

## プロンプト作成の原則

1. **簡潔な英語で指示する**: 外部ワーカーへのプロンプトは英語で記述する．自己完結した文脈 (対象ファイル，既存の構造，ゴール)を渡す．
2. **対象ファイルの排他指定 (`Exclusive Target Files`)**: 編集を許可するファイルパスを明示し，それ以外のファイル (特にドキュメントや他ワーカーの担当ファイル)を触らせない．
3. **コメント規約と出力抑制の明記**: プロンプト末尾に以下の制約を含める:
   - `Exclusive Scope: Modify ONLY the specified target files.`
   - `No explanatory or obvious comments. Self-documenting naming only (hush rule).`
   - `Do NOT run nix flake check or nix build.`
   - `Report summary bullets of changes and reasoning only. Do NOT re-print full files or large code blocks.`
