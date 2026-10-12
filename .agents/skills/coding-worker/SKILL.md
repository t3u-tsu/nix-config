---
name: coding-worker
description: >-
  Delegate implementation, refactoring, and technical review tasks to external coding workers (pi, dsh, codewhale, etc.).
  Strictly for Antigravity (Gemini) orchestration — worker agents must NOT invoke this skill.
disable-model-invocation: true
---

# Coding Worker

外部コーディングワーカー（pi, dsh, codewhale）に対するコード実装・リファクタリングおよび技術レビューの委譲仕様である．本スキルは親オーケストレーター専用であり，呼び出される側のワーカー自身は参照しない．

## 実行スクリプト仕様

コーディングタスクの委譲には，`scripts/run.ysh` を使用する．

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

### 終了コード

| 終了コード | 意味 |
| :--- | :--- |
| `0` | 正常終了． |
| `1` | 引数不正，再帰呼び出し制限超過（`__CODING_WORKER_DEPTH >= 2`），または非対応ワーカーでの `--read-only` 指定． |
| `2`（またはワーカー固有） | ワーカープロセスの異常終了（ワーカープロセスの終了コードを透過）． |
| `3` | `--read-only` 実行中にワーキングツリーの変更を検知（フィンガープリント不一致）． |

## 並列ワーカー実行の技術仕様

同一タスクグループ配下の独立した兄弟ワークツリー（`.worktrees/<topic>/worker-<name>/` 等）を作業ディレクトリとして各ワーカーに割り当てることで，複数のワーカーを完全並列に実行できる．ワークツリーの作成や差分統合の手順は `orchestration` スキルに従う．

- **Git 状態の完全分離**: 各兄弟ワークツリーは独立したインデックス（`.git` index）と作業ツリーを持つため，複数ワーカーが同時にファイルを操作・検証しても Git のロック競合やステージングの干渉が発生しない．
- **セッション状態の分離**: `.agents/skills/coding-worker/.state/` は各ワークツリー配下に独立して保持されるため，セッション記録（`last.session`，`task_${TASK_ID}.session`）やログファイルがワーカー間で衝突しない．

### 複数ワーカーの並列実行手順

親オーケストレーターが複数のワーカーを稼働させる標準手順は以下の通りである．

1. **兄弟ワークツリーの事前一括作成**:
   タスク分解に基づき，必要な作業ツリーを `.worktrees/<topic>/` 配下に一括で展開する（詳細コマンドは `orchestration` スキル参照）．
   ```bash
   # 例: 2つの独立実装タスク用に兄弟ツリーを一括作成
   git worktree add -b feat/task-dns .worktrees/dns-migration/worker-dns origin/main
   git worktree add -b feat/task-dhcp .worktrees/dns-migration/worker-dhcp origin/main
   ```
2. **バックグラウンドでの並列一括起動**:
   各ワークツリーを作業ディレクトリ（`Cwd`）として指定し，直列に待たずに `run.ysh` を連続して非同期起動する．親エージェントは小刻みなポーリングや直前の完了待ちを行わず，すべてのワーカーを同時に走らせる．
   ```bash
   # ワーカー 1 起動 (Cwd: .worktrees/dns-migration/worker-dns)
   .agents/skills/coding-worker/scripts/run.ysh "<PROMPT_DNS>"

   # ワーカー 2 起動 (Cwd: .worktrees/dns-migration/worker-dhcp)
   WORKER=dsh .agents/skills/coding-worker/scripts/run.ysh "<PROMPT_DHCP>"
   ```
3. **作業ツリーへの差分生成**:
   各ワーカーはそれぞれの兄弟ワークツリー内で変更を生成する．
4. **差分の抽出と統合**:
   全ワーカーのバックグラウンド完了通知を受けた後，または個別完了ごとに親エージェントが各ツリーから差分を抽出し，統合用ワークツリー（`main/`）へ取り込む（統合コマンドは `orchestration` スキル参照）．

### ワーカー種別の柔軟な使い分け

各ワーカー（`pi`, `dsh`, `codewhale`）は同一のバックエンド API キーを共有しており，ハーネス（実行基盤）の実装構造に応じた特性を持つ．

- **原則として `pi` を使用（デフォルト）**:
  最も標準的な運用．進捗ストリーミング，構造化出力，ツリー変更防止（`--read-only`）など，呼び出される側として効率的に設計されているため，通常の実装・レビューは `pi` をデフォルトとする．複数ツリーで `pi` 同士を同時起動して並行運用可能．
- **場合に応じた `dsh` や `codewhale` の選択**:
  タスクの特性や目的に応じて選択・並行運用できる．
  - `dsh`: ハーネスとしての今後の台頭・活用を視野に入れており，大規模なスクリプト生成や広範なリファクタリングなどで適宜活用可能．
  - `codewhale`: 過去に使用していたバックエンドであり，互換性確認や比較検証などで利用可能．
- **複数種別の組み合わせ運用**:
  ハーネス特性やタスク適性に応じ，別個の兄弟ワークツリーで組み合わせて並行投入できる．
  - 例1: モジュール A の実装（`WORKER=pi`）とモジュール B の実装（`WORKER=dsh`）を同時に走らせる．
  - 例2: モジュール実装（`WORKER=pi`）と先行完了分の技術レビュー（`WORKER=dsh`）を並行して実行する．

## プロンプトの設計原則

コーディングワーカーへ渡すプロンプトは簡潔かつ明確な英語で記述する．子ワーカーに親のオーケストレーション規約や無関係なドキュメントを読ませず，タスク目標と対象ファイルのみにコンテキストを絞り込むことで，トークン消費を抑えつつ精度を高める．

### 必須制約
1. **コンテキストの最小化（トークン消費の削減とタスクの明確化）**:
   親オーケストレーター向けの運用ルールやリポジトリ全体のドキュメントを子ワーカーに読ませず，達成すべき具体的な目標や要件，排他的な担当ファイルのみを指示する．不要なコンテキストを遮断することで，トークン消費を抑え，目的外のファイル探索や変更を防ぐ（"Focus strictly on the assigned task and files. Do NOT explore or modify unrelated areas."）．
2. **担当ファイルの排他指定（競合防止）**:
   複数ワーカーが並列稼働する場合，統合時のコンフリクトを避けるため，各ワーカーに担当ファイル・ディレクトリを明示し，対象外の変更を厳格に禁止する（"Exclusive File Scope: You are strictly responsible ONLY for the files listed. Modifying any other files is strictly FORBIDDEN."）．
3. **hush 規約の遵守**:
   自明な解説や言い換えコメントの付与を禁じる（"No explanatory or restating comments. Self-documenting naming only."）．
4. **スコープの限定**:
   ドキュメントや README など実装対象外のファイルを変更させない（"Do NOT edit documentation or README files."）．
5. **要約箇条書きの要求**:
   全文の再掲を禁止し，変更内容と根拠の箇条書きのみを報告させる（"Report summary bullets of changes and reasoning only. Do NOT re-print full files or large code blocks."）．

### プロンプトテンプレート

#### 並行実装タスク（推奨）
```text
Task: <goal>
Exclusive Target Files:
- <file_1>
- <file_2>
Instructions: <concise steps>
Constraints:
- Exclusive Scope: You are strictly responsible ONLY for the target files listed above. Do NOT modify, create, or touch any other files under any circumstances.
- No explanatory or obvious comments. Self-documenting naming only (hush rule).
- Do NOT edit documentation or README files.
- Follow nixpkgs conventions and formatting.
- Report summary bullets of changes and reasoning only. Do NOT re-print full files or large code blocks.
```

#### 技術レビュー（改善差分の直接作成・推奨）
```text
Task: Review and improve the current changes
Review Target: origin/main..HEAD
Target Files: <list of specific files to touch>
Focus: <e.g. systemd service definitions, restic restore logic, networking>
Instructions:
- Verify that commands, unit names, and Nix options match actual repository configs.
- Identify edge cases, race conditions, permission issues, or missing steps.
- Directly apply suggested fixes and improvements to the target files only.
Constraints:
- Exclusive Scope: Modify ONLY the specified target files.
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
