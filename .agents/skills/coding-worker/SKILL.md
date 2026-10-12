---
name: coding-worker
description: >-
  Delegate implementation, refactoring, and technical review tasks to external coding workers (pi, dsh, codewhale, etc.).
  Strictly for Antigravity (Gemini) orchestration — worker agents must NOT invoke this skill.
disable-model-invocation: true
---

# Coding Worker

外部コーディングワーカー（pi, dsh, codewhale）に対するコード実装・リファクタリングおよび技術レビューの委譲仕様である．本スキルは親オーケストレーター専用であり，呼び出される側のワーカー自身は参照しない．

> [!NOTE]
> 並列実行時の兄弟ワークツリー作成，非同期パイプライン化，先行作業の進行，および差分統合の手順など，オーケストレーション全般の基本事項は `orchestration` スキル（`.agents/skills/orchestration/SKILL.md`）を参照する．本スキルは，実行スクリプト（`run.ysh`）の仕様・使い方および外部コーディングワーカー固有の注意事項・プロンプト設計に特化している．

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

### セッションの継続と対話的改善（CONTINUE / TASK_ID）

ワーカーの初回実行後，追加の修正や改善を同一コンテキスト（直前の会話履歴，コード変更，検討内容）を引き継いで行わせたい場合は `CONTINUE=1` や `TASK_ID` を使用する．

- **使用シーン**:
  - **追加修正・テスト追加**: 初回ワーカーの変更や stat を確認した後，「テストケースも追加してほしい」「このエッジケースも考慮して修正してほしい」と追加指示を出す場合．
  - **ビルド・検証エラーの修正**: ワーカーの変更後に `nix build` や `flake check` を実行してエラーが発生した際，エラーログを渡して「このエラーを修正してほしい」と修正を指示する場合．
  - **段階的なリファクタリング**: 実装完了後に同一コンテキストで「関数名をより簡潔にリファクタリングしてほしい」など追加指示を行う場合．
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
  `TASK_ID` を指定してセッションを名指しで管理することも可能:
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

親オーケストレーターが Antigravity サブエージェント（`invoke_subagent`）ではなく外部コーディングワーカー（`run.ysh`）を使用する際に，特有として気をつけるべき原則である．

> [!NOTE]
> 複数ワーカーの並列実行における兄弟ワークツリーの作成，非同期パイプライン化，先行作業の進行，および差分統合の手順，ならびにワーカー種別（`pi`, `dsh`, `codewhale`）の使い分け・組み合わせ運用方針は，`orchestration` スキル（`.agents/skills/orchestration/SKILL.md`）を参照する．

### 1. 英語プロンプトの原則
Antigravity サブエージェントとは日本語で指示・対話し，ドキュメント等の推敲を行わせるが，外部コーディングワーカー（`pi`, `dsh` 等）には **必ず簡潔で明確な英語（English）** でプロンプトを指示する．日本語の指示や過剰な文脈を与えると，ワーカーの推論精度低下や不要な探索を招く原因となる．

### 2. hush 規約の英語制約指示
サブエージェントには `hush` スキルを直接参照させることができるが，外部ワーカーにはプロンプト内に英語で直接制約を与える（`No explanatory or obvious comments. Self-documenting naming only (hush rule).`）．ワーカーはコメントを過剰に追加しがちであるため，必ず英語制約としてプロンプトに明示する．

### 3. 実装専念とスコープの限定
外部ワーカーはコード実装・修正に専念させる．ドキュメントや README などの修正はワーカーには行わせず（`Do NOT edit documentation or README files.`），サブエージェントに委譲する．

### 4. 出力トークンの抑制（全文再掲の禁止）
CLI 実行される外部ワーカーがファイル全文や巨大なコードブロックを標準出力に再掲すると，トークン消費やバッファ溢れの原因となる．変更内容と理由の簡潔な箇条書きのみを報告させる制約を課す（`Report summary bullets of changes and reasoning only. Do NOT re-print full files or large code blocks.`）．

### 5. 担当ファイルの排他指定（統合コンフリクト回避）
兄弟ワークツリーによって Git 状態や作業ディレクトリは物理的に分離されているため，作業中のファイル衝突やロック競合は起きない．スコープを排他指定する真の理由は，**各ワーカーの担当責務を明確にし，最終的に統合用ツリー（`main/`）へ差分統合（パッチ適用/マージ）する際のコンフリクトを回避するため**である（`Exclusive File Scope: You are strictly responsible ONLY for the target files listed above.`）．

### 6. レビューモードとワーキングツリー不変の保証
外部ワーカーにレビューを行わせる際，作業ツリーを変更させずに指摘のみを取得したい場合は `--read-only` モードを使用する．`worker=pi` のツール制限と Git フィンガープリント照合により，ツリーが変更されていないことが保証される（変更が検知されると終了コード 3 で異常終了する）．一方，改善差分を直接作成させたい場合は通常の編集可能モードで実行する．

### 7. 対話的改善とセッション継続
初回の実装や検証後にビルドエラーが発生した場合や追加要件が生じた場合は，新規セッションを起こさず `CONTINUE=1` や `TASK_ID` を指定して同一コンテキストで対話を継続する．兄弟ワークツリーごとに `.agents/skills/coding-worker/.state/` が分離されているため，並列稼働中の他ワーカーと干渉せずに安全に継続できる．

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
