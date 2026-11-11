---
name: coding-worker
description: >-
  Delegate implementation, refactoring, investigation, documentation, and review tasks to external workers (pi, dsh, codewhale) via .agents/skills/coding-worker/scripts/run.ysh to combine non-Gemini model strengths.
  Proactively use on an equal footing with subagents without waiting for explicit user requests.
---

# Coding Worker

[scripts/run.ysh](scripts/run.ysh) を用いて外部ワーカー (`pi`, `dsh`, `codewhale`)にコード実装・リファクタリング・原因調査・設計検証・ドキュメント作成・レビューを委譲する手順．ユーザーの明示的な指示を待たず，内蔵サブエージェント (`invoke_subagent`)と同列の手段として自律的にディスパッチし，Gemini 以外のモデルの特性を組み合わせる．親セッション専用であり，サブエージェントや `run.ysh` で起動されたワーカー自身は本スキルを実行しない．複数の独立タスクを並列ディスパッチする際の判断基準は `dispatching-parallel-agents` スキル (`~/.agents/skills/dispatching-parallel-agents/`)を参照．

## 基本使用方法

オプション (`--read-only`)は必ずプロンプト引数より前に指定し，プロンプトは引用符で囲んで 1 つの引数として渡す:

```bash
# 実装・リファクタリング・ドキュメント作成 (ワークツリー内で実行)
cd .worktrees/<topic>/main && .agents/skills/coding-worker/scripts/run.ysh "<PROMPT_IN_ENGLISH>"

# 改善差分を直接作成させる技術・ドキュメントレビュー
cd .worktrees/<topic>/main && .agents/skills/coding-worker/scripts/run.ysh "Review the diff origin/main..HEAD for technical correctness and documentation rules, and apply necessary improvements."

# 読み取り専用の調査・設計比較・セカンドオピニオン・レビュー (ワーキングツリーを変更しない，セッション保存なし)
cd .worktrees/<topic>/main && .agents/skills/coding-worker/scripts/run.ysh --read-only "Analyze <target> and propose design trade-offs / review origin/main..HEAD."

# セッション継続 (直前セッション，または特定 TASK_ID セッション)
cd .worktrees/<topic>/main && CONTINUE=1 .agents/skills/coding-worker/scripts/run.ysh "<FOLLOW_UP_PROMPT>"
cd .worktrees/<topic>/main && CONTINUE=1 TASK_ID="feat-dns" .agents/skills/coding-worker/scripts/run.ysh "<FOLLOW_UP_PROMPT>"
```

ワークツリー内で複数ワーカーを並列起動する場合は，単一の作業ワークツリー上で対象ファイルを排他指定 (`Exclusive Target Files`)し，セッション上書きを防ぐため必ず個別の `TASK_ID` を付与して実行する (Antigravity (`agy`)では `run_command` に `WaitMsBeforeAsync: 500` を指定し，`invoke_subagent` も含めて同一ターン内で同時発行する):

```bash
cd .worktrees/<topic>/main && TASK_ID="worker-a" .agents/skills/coding-worker/scripts/run.ysh "<PROMPT_A>"
cd .worktrees/<topic>/main && TASK_ID="worker-b" .agents/skills/coding-worker/scripts/run.ysh "<PROMPT_B>"
```

同一ワークツリーで並列実行した場合，出力末尾の `[status]` と `[stat]` には他ワーカーの変更も含まれる．並列実行後に特定ワーカーのセッションを継続する場合は，単独の `CONTINUE=1` ではなく必ず `CONTINUE=1 TASK_ID="worker-a"` のように `TASK_ID` を併用する．

## オプションと環境変数

- `--read-only` (または `READ_ONLY=1`):
  ワーキングツリーの変更を禁止する読み取り専用モード (`worker=pi` 専用)．書き込み系ツールを無効化し，実行前後のワークツリー全体の Git フィンガープリントを照合して変更が検知された場合は終了コード `3` で失敗する (そのため同一ツリー上でファイル編集を行う他ワーカーとは並列実行しない)．セッションは保存されず `CONTINUE` は無効となる．

| 変数 | デフォルト | 説明 |
| :--- | :--- | :--- |
| `WORKER` | `pi` | 使用するワーカーバックエンド (`pi`, `dsh`, `codewhale`)． |
| `TASK_ID` | (空) | タスク識別子を指定してセッションを個別に保存する (`[a-zA-Z0-9._-]` 以外の文字は `_` に置換される)． |
| `CONTINUE` | `0` | `1` (文字列 `'1'` のみ有効)でセッションを継続する (`TASK_ID` 併用時はそのタスク，未指定時は直前セッション)． |
| `READ_ONLY` | `0` | `1` (`true` / `yes` 可)で `--read-only` モードを有効化する (`worker=pi` 専用)． |
| `EXTRA_FLAGS` | (空) | ワーカー実行バイナリへ追加で渡す任意フラグ． |

## 終了コード

| 終了コード | 意味 |
| :--- | :--- |
| `0` | 正常終了． |
| `1` | 引数不正，未定義の `WORKER`，保存済みセッションが存在しない `TASK_ID` での `CONTINUE=1`，再帰呼び出し制限超過 (`__CODING_WORKER_DEPTH >= 2`)，非対応ワーカーでの `--read-only` 指定，またはワーカー自身の終了コード `1`． |
| `2` (またはワーカー固有) | ワーカープロセスの異常終了 (ワーカーの終了コードをそのまま透過)． |
| `3` | `--read-only` 実行中にワーキングツリーの変更を検知． |

## プロンプト作成の原則

1. 外部ワーカーへのプロンプトは簡潔な英語で記述し，自己完結した文脈 (対象ファイル，既存の構造，ゴール)を渡す．
2. 編集を許可するファイルパス (`Exclusive Target Files`)を明示し，それ以外のファイル (ドキュメントや他ワーカーの担当ファイル)を変更させない．
3. プロンプト末尾に以下の制約を含める:
   - `Exclusive Scope: Modify ONLY the specified target files.`
   - `Do NOT run git add, git commit, or modify git state.`
   - `Do NOT run nix flake check or nix build.`
   - `No explanatory or obvious comments. Self-documenting naming only (hush rule).`
   - `Report summary bullets of changes and reasoning only. Do NOT re-print full files or large code blocks.`
