---
name: coding-worker
description: >-
  Delegate implementation, refactoring, and technical review tasks to external coding workers (pi, dsh, codewhale, etc.).
  Strictly for Antigravity (Gemini) orchestration — worker agents must NOT invoke this skill.
disable-model-invocation: true
---

# Coding Worker

外部コーディングワーカー（pi, dsh, codewhale）に対するコード実装・リファクタリング・技術レビューの委譲仕様．親オーケストレーター専用であり，ワーカー自身は本スキルを参照しない．

## 実行スクリプト仕様

コーディングタスクの委譲には，[`scripts/run.ysh`](scripts/run.ysh) を使用する．

### 基本使用方法

```bash
# 実装・リファクタリング
.agents/skills/coding-worker/scripts/run.ysh "<PROMPT_IN_ENGLISH>"

# 改善差分を直接作成させる技術レビュー（推奨）
.agents/skills/coding-worker/scripts/run.ysh "Review the diff origin/main..HEAD for technical correctness and apply necessary improvements."

# 読み取り専用レビュー（指摘のみを取得しワーキングツリーを変更しない）
.agents/skills/coding-worker/scripts/run.ysh --read-only "Review the diff origin/main..HEAD for technical correctness."

# セッション継続（直前セッション，または特定 TASK_ID セッション）
CONTINUE=1 .agents/skills/coding-worker/scripts/run.ysh "<FOLLOW_UP_PROMPT>"
CONTINUE=1 TASK_ID="feat-dns" .agents/skills/coding-worker/scripts/run.ysh "<FOLLOW_UP_PROMPT>"
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
| `TASK_ID` | （空） | タスク識別子を指定して会話ターンをグループ化する（例: `feat-dns`）．継続には `CONTINUE=1` が必要． |
| `CONTINUE` | `0` | `1` でセッションを継続する（`TASK_ID` 併用時はそのタスク，未指定時は直前セッション）． |
| `READ_ONLY` | `0` | `1` で `--read-only` モードを有効化する（`worker=pi` 専用）． |
| `EXTRA_FLAGS` | （空） | ワーカー実行バイナリへ追加で渡す任意フラグ． |

### セッションの継続と対話的改善（CONTINUE / TASK_ID）

ワーカー実行後，直前の会話履歴・差分・検討内容を引き継いで追加修正する場合は `CONTINUE=1` を使用する（`TASK_ID` 併用で特定タスクのセッションを継続可能）．

- **使用シーン**:
  - **追加修正・テスト追加**: 初回ワーカーの変更や stat を確認した後，「テストケースも追加してほしい」「このエッジケースも考慮して修正してほしい」と追加指示を出す場合．
  - **ビルド・検証エラーの修正**: ワーカーの変更後に `nix build` や `flake check` を実行してエラーが発生した際，エラーログを渡して「このエラーを修正してほしい」と修正を指示する場合．
  - **段階的なリファクタリング**: 実装完了後に同一コンテキストで「関数名をより簡潔にリファクタリングしてほしい」などの追加指示を出す場合．
- **ワークツリーごとの状態分離**:
  各兄弟ワークツリー配下の `.agents/skills/coding-worker/.state/` は独立して保持されているため，ツリー内で安全に対話を継続できる．別ツリーで並列稼働している他ワーカーのセッションと干渉・混同することはない．
- **具体例**:
  ```bash
  # 兄弟ツリー (.worktrees/dns-migration/worker-dns) 内での対話例:

  # 1. 初回実装を指示
  .agents/skills/coding-worker/scripts/run.ysh "Implement DNS zone configuration in hosts/torii-chan/dns.nix"

  # （結果の diff や検証を確認後，ビルドエラーや追加要件が発生）

  # 2. 直前のセッションを引き継いでエラー修正・テスト追加を指示
  CONTINUE=1 .agents/skills/coding-worker/scripts/run.ysh "The build failed with 'attribute dns_records missing'. Fix the syntax and add a unit test in tests/dns.nix."
  ```
  `TASK_ID` を指定してセッションを個別に管理する:
  ```bash
  # 特定タスク ID で初回起動
  TASK_ID="dns-zone" .agents/skills/coding-worker/scripts/run.ysh "Implement DNS zone configuration..."

  # 同じタスク ID を指定して継続
  TASK_ID="dns-zone" CONTINUE=1 .agents/skills/coding-worker/scripts/run.ysh "Fix build failure..."
  ```

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

## 外部ワーカー固有の注意事項（サブエージェントとの相違点）

親オーケストレーターが外部コーディングワーカー（`run.ysh`）を使用する際の固有原則．

> [!NOTE]
> 兄弟ワークツリーの作成，並列投入，非同期逐次合流，排他指定，差分統合の手順は [`GEMINI.md`](../../../GEMINI.md) を参照．

### 1. 英語プロンプトの原則
外部コーディングワーカー（`pi`, `dsh` 等）へのプロンプトは **簡潔で明確な英語（English）** で指示する．日本語の指示や過剰な文脈は推論精度の低下や不要な探索を招く．

### 2. hush 規約の英語制約指示
外部ワーカーには `hush` スキルの制約をプロンプト内に英語で直接指示する（`No explanatory or obvious comments. Self-documenting naming only (hush rule).`）．過剰なコメント追加を避けるため，プロンプト内で明示的に制約する．

### 3. 実装専念とスコープの限定
外部ワーカーのスコープはコード実装・修正に限定する（`Do NOT edit documentation or README files.`）．ドキュメント改修はサブエージェントに委譲する．

### 4. 出力トークンの抑制（全文再掲の禁止）
ファイル全文や長大なコードブロックの再掲を禁じ，変更内容と理由の簡潔な箇条書きのみを報告させる（`Report summary bullets of changes and reasoning only. Do NOT re-print full files or large code blocks.`）．

### 5. レビューモードとワーキングツリー不変の保証（`--read-only`）
指摘のみを取得し作業ツリーを変更させない場合は `--read-only` モードを使用する．ツール制限と Git フィンガープリント照合によりツリー不変を保証する（変更検知時は終了コード 3 で失敗）．改善差分を直接作成させる場合は通常の編集可能モードで実行する．

### 6. 対話的改善とセッション継続（`CONTINUE=1`, `TASK_ID`）
初回実行後のエラー修正や追加要件は `CONTINUE=1`（特定タスクは `TASK_ID` 併用）で同一コンテキストを継続する．兄弟ツリーごとに `.agents/skills/coding-worker/.state/` が分離されているため，他ワーカーと干渉せず安全に対話を継続できる．

## プロンプトテンプレート

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
