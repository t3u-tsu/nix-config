---
name: coding-worker
description: >-
  Delegate implementation, refactoring, and technical review tasks to external coding workers (pi, dsh, codewhale, etc.).
  Strictly for Antigravity (Gemini) orchestration — worker agents must NOT invoke this skill.
disable-model-invocation: true
---

# Coding Worker

外部コーディングワーカー（pi，dsh，codewhale）に対するコード実装・リファクタリングおよび技術レビューの委譲仕様．本スキルは Antigravity（親オーケストレーター）専用であり，呼び出される側のコーディングワーカー自身は参照しない．

## 実行スクリプト仕様

コーディングタスクの委譲には，モダンな YSH 実装の `scripts/run.ysh` を使用する．Oil/YSH 組み込みの JSON パーサーを使用するため，外部ツール（`jq`）への依存がない．

### 基本使用方法

```bash
# 実装・リファクタリング
.agents/skills/coding-worker/scripts/run.ysh "<PROMPT_IN_ENGLISH>"

# 改善差分を直接作成させる技術レビュー（推奨）
.agents/skills/coding-worker/scripts/run.ysh "Review the diff origin/main..HEAD for technical correctness and apply necessary improvements."

# 読み取り専用レビュー（指摘のみを取得しワーキングツリーを変更しない）
.agents/skills/coding-worker/scripts/run.ysh --read-only "Review the diff origin/main..HEAD for technical correctness."

# セッション継続・特定セッション ID 指定
CONTINUE=1 .agents/skills/coding-worker/scripts/run.ysh "<FOLLOW_UP_PROMPT>"
TASK_ID="feat-dns" .agents/skills/coding-worker/scripts/run.ysh "<PROMPT_IN_ENGLISH>"
```

### オプションとフラグ

- `--read-only`（または `READ_ONLY=1`）:
  ワーキングツリーの変更を禁止する読み取り専用レビューモード．`worker=pi` 専用（`pi` 以外ではエラー終了）．
  - ツール実行を事前制限（`--tools read,bash,grep,find,ls --exclude-tools edit,write --no-session --no-mcp`）．
  - 実行前後のツリーフィンガープリント（`git rev-parse HEAD`，`git status --porcelain`，`git diff`，`git diff --cached`，`git ls-files --others --exclude-standard`）を照合し，変更が検知された場合は差分を出力して終了コード 3 で失敗する．
  - セッションは保存・継続されない．

### 環境変数

| 変数 | デフォルト | 説明 |
| :--- | :--- | :--- |
| `WORKER` | `pi` | 使用するワーカーバックエンド（`pi`, `dsh`, `codewhale`）． |
| `TASK_ID` | （空） | セッション ID を明示して会話ターンをグループ化する（例: `feat-dns`）． |
| `CONTINUE` | `0` | `1` で直前のセッションを継続する． |
| `READ_ONLY` | `0` | `1` で `--read-only` モードを有効化する（`worker=pi` 専用）． |
| `EXTRA_FLAGS` | （空） | ワーカー実行バイナリへ追加で渡す任意フラグ． |

### 進捗ストリーミングと出力形式

`worker=pi` は `--mode json` でイベントストリームを逐次処理し，ツールの進捗を stderr へ，最終結果を stdout へ出力する．

- **stderr（進捗ストリーミング）**:
  ツール実行開始ごとに1行出力:
  ```text
  [pi] tool: <toolName> (<target>)
  ```
  - `read` / `edit` / `write`: `<target>` はファイルパス．
  - `bash`: `<target>` はコマンド文字列（60文字超は省略）．
  - その他ツール: 主要引数のキー・値要約．

- **stdout（構造化結果）**:
  ```text
  worker: <worker> (session: <session_id>, exit: <exit_code>)
  log: <log_path>

  [response]
  <assistant の最終応答テキスト>

  [status]
  <git status --short，変更なしは "  (clean)">

  [stat]
  <git diff --stat，差分なしは "  (no diff)">
  ```
  - `session:` はセッションが存在する場合のみ表示される（`--read-only` 時は省略）．
  - 終了コードが 0 以外の場合は末尾に `[error]` セクション（ログ末尾20行）が付加される．
  - 全イベントストリームと診断ログは `log:` のパスに記録される．

`worker=dsh` / `worker=codewhale` はストリーミングを行わず，stdout に応答テキスト，stderr にログを出力する．

### 終了コード（Exit Codes）

| 終了コード | 意味 |
| :--- | :--- |
| `0` | 正常終了． |
| `1` | 引数不正，再帰呼び出し制限超過（`__CODING_WORKER_DEPTH >= 2`），または非対応ワーカーでの `--read-only` 指定． |
| `2`（またはワーカー固有） | ワーカープロセスの異常終了（ワーカープロセスの終了コードを透過）． |
| `3` | `--read-only` 実行中にワーキングツリーの変更を検知（フィンガープリント不一致）． |

## 並列ワーカー実行の技術仕様

同一タスクグループ配下の独立した兄弟ワークツリー（`.worktrees/<topic>/worker-<name>/` 等）を作業ディレクトリとして各ワーカーに割り当てることで，複数のワーカーを完全並列に実行できる．ワークツリーの作成や差分統合の手順は `dev-workflow` スキル（SSOT）に従う．

- **Git 状態の完全分離**: 各兄弟ワークツリーは独立したインデックス（`.git` index）と作業ツリーを持つため，複数ワーカーが同時にファイルを操作・検証しても Git ロック競合やステージング干渉が発生しない．
- **セッション状態の分離**: `.agents/skills/coding-worker/.state/` は各ワークツリー配下に独立して保持されるため，セッション記録（`last.session`，`task_${TASK_ID}.session`）やログファイルがワーカー間で衝突しない．
- **実行と差分統合の技術フロー**:
  1. 親エージェントが `.worktrees/<topic>/` 配下に兄弟ワークツリーを作成する（作成手順は `dev-workflow` 参照）．
  2. 各ワークツリーを作業ディレクトリとして `run.ysh` をバックグラウンドで同時起動する．
  3. 各ワーカーは未コミットの差分を兄弟ワークツリー内に生成する．
  4. 親エージェントは未コミット変更を含めて差分を抽出し，`main/` ワークツリーへ統合・マージする（統合コマンドは `dev-workflow` 参照）．

## プロンプティング原則

コーディングワーカーへ渡すプロンプトは簡潔かつ明確な英語で記述し，以下の制約を遵守させる．

### 必須制約
1. **hush 規約の遵守**: 自明な解説や言い換えコメントの付与を禁じる（"No explanatory or restating comments. Self-documenting naming only."）．
2. **スコープの限定**: ドキュメントや README など実装対象外のファイルを変更させない（"Do NOT edit documentation or README files."）．
3. **要約箇条書きの要求**: 全文再掲を禁止し，変更内容と根拠の箇条書きのみを報告させる（"Report summary bullets of changes and reasoning only. Do NOT re-print full files or large code blocks."）．

### プロンプトテンプレート

#### 実装タスク
```text
Task: <goal>
Target files: <list of files>
Instructions: <concise steps>
Constraints:
- No explanatory or obvious comments. Self-documenting naming only.
- Do NOT edit documentation or README files.
- Follow nixpkgs conventions and formatting.
- Report summary bullets of changes and reasoning only. Do NOT re-print full files or large code blocks.
```

#### 技術レビュー（改善差分作成・推奨）
```text
Task: Review and improve the current changes
Review Target: origin/main..HEAD
Focus: <e.g. systemd service definitions, restic restore logic, networking>
Instructions:
- Verify that commands, unit names, and Nix options match actual repository configs.
- Identify edge cases, race conditions, permission issues, or missing steps.
- Directly apply suggested fixes and improvements to the target files.
Constraints:
- Follow hush conventions (no explanatory or restating comments).
- Do NOT edit documentation or README files.
- Follow nixpkgs conventions and formatting.
- Report summary bullets of changes and reasoning only. Do NOT re-print full files or large code blocks.
```

#### 技術レビュー（読み取り専用）
```text
Review Target: <diff range or file paths>
Focus: <e.g. systemd service definitions, restic restore logic, networking>
Instructions:
- Verify that commands, unit names, and Nix options match actual repository configs.
- Identify edge cases, race conditions, permission issues, or missing steps.
- Provide concrete suggested fixes with small code snippets only.
- Report summary bullets of findings and reasoning only. Do NOT re-print full files or large code blocks.
```
