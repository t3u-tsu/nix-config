---
name: coding-worker
description: >-
  Delegate implementation, refactoring, and technical review tasks to external coding workers (pi, dsh, codewhale, etc.).
  Strictly for Antigravity (Gemini) orchestration — worker agents must NOT invoke this skill.
disable-model-invocation: true
---

# Coding Worker

外部コーディングワーカー（pi，dsh，codewhale）に対するコード実装・リファクタリングおよび技術レビューの委譲仕様．

## スクリプト仕様

### 実行スクリプト (`scripts/run.sh`)

コードの新規作成，編集，リファクタリング，改善差分を伴うレビュー，および読み取り専用（Read-Only）の技術レビューをワーカーに委譲する（従来の `review.sh` は `run.sh` の `--read-only` へ統合・一本化された）．

- **基本実行（実装・改善差分の作成）**:
  一時ワークツリー内でワーカーを実行し，コードの実装や改善差分を直接作成させる．Antigravity Main やユーザーは `git diff` を検証し，妥当な変更のみを取り込む（取捨選択する）．
  ```bash
  # 実装タスク
  .agents/skills/coding-worker/scripts/run.sh "<PROMPT_IN_ENGLISH>"

  # 改善差分を直接作成させる技術レビュー（推奨）
  .agents/skills/coding-worker/scripts/run.sh "Review the diff origin/main..HEAD for technical correctness and apply necessary improvements."
  ```
- **読み取り専用レビュー（Read-Only）**:
  差分を変更させず指摘のみを取得したい場合は `--read-only`（または `READ_ONLY=1`）を指定する．`--read-only` は事前ツール制限（`--tools read,bash,grep,find,ls --exclude-tools edit,write --no-session --no-mcp`）をサポートしている `pi` 専用のモードであり，`pi` 以外のワーカーを指定した場合はエラー終了する．実行前後のツリーフィンガープリント（`git rev-parse HEAD`，`git status --porcelain`，`git diff`，`git diff --cached`，`git ls-files --others --exclude-standard`）が一致しない場合は終了コード 3 で失敗する．セッションは継続・保存されない．
  ```bash
  .agents/skills/coding-worker/scripts/run.sh --read-only "Review the diff origin/main..HEAD for technical correctness."
  ```
- **セッション継続**:
  ```bash
  CONTINUE=1 .agents/skills/coding-worker/scripts/run.sh "<FOLLOW_UP_PROMPT>"
  ```
- **セッション ID 指定**:
  ```bash
  TASK_ID="feat-dns" .agents/skills/coding-worker/scripts/run.sh "<PROMPT_IN_ENGLISH>"
  ```
- **ワーカー切り替え**:
  環境変数 `WORKER` で指定（デフォルト: `pi`，利用可能: `pi`, `dsh`, `codewhale`）．
  ```bash
  WORKER=dsh .agents/skills/coding-worker/scripts/run.sh "<PROMPT_IN_ENGLISH>"
  ```

### 進捗ストリーミングと出力形式

`worker=pi` は `--mode json` でイベントストリームを逐次読み取り，進捗を stderr へ，最終応答と状態を stdout へ出力する．親エージェントは stdout を構造化出力として解釈し，stderr でツール実行の進捗をリアルタイムに確認できる．

ツール実行開始ごとに次の1行を stderr へ出力する:

```text
[pi] tool: <toolName> (<target>)
```

- `read` / `edit` / `write`: `<target>` は対象パス．
- `bash`: `<target>` はコマンド（60文字を超える場合は切り詰め）．
- その他のツール: 主要引数の要約（例: `pattern=foo`）．

完了時は stdout へ次の構造化テキストを出力する（`===` 等の装飾バナーは使わない）:

```text
worker: <worker> (session: <session_id>, exit: <exit_code>)
log: <log_path>

[response]
<assistant の最終テキスト>

[status]
<git status --short，変更がなければ "  (clean)">

[stat]
<git diff --stat，差分がなければ "  (no diff)">
```

- `session:` はセッションが存在する場合のみ表示する（読み取り専用モードは `--no-session` のため省略される）．
- `[response]` はストリーム中の `message_end`（assistant）から抽出した最終テキストである．
- 終了コードが 0 以外の場合は末尾に `[error]` セクションとしてログ末尾を出力する．
- 全イベントと診断（pi の stderr を含む）は `log` に記録される．
- 読み取り専用モードでは，実行前後のフィンガープリントが一致しない場合に終了コード 3 で失敗する．

`worker=dsh` / `worker=codewhale` は従来どおり stdout を最終応答，stderr をログとして扱い，進捗ストリーミングは行わない．

## 並列ワーカー実行（Multiple Concurrent Workers）

同一タスクグループ配下の独立した兄弟ワークツリー（`.worktrees/<topic>/worker-<name>/` など）を各ワーカーに割り当てることで，同一種別（複数の `pi` など）を含む複数のコーディングワーカーを完全並列に実行できる．

- **完全な状態分離**: 各兄弟ワークツリーごとに作業ディレクトリ，Git ロック/インデックス，およびセッション状態（`TASK_ID` や会話履歴）が完全に分離され，競合が発生しない．
- **オーケストレーションフロー**:
  1. 親エージェントが `.worktrees/<topic>/` 配下に兄弟ワークツリー（例: `worker-pi-feature/`，`worker-pi-tests/`）を作成する．
  2. 各ワークツリーを作業場所として `run.sh` を同時にバックグラウンド起動する．
  3. 各ワーカーの完了通知を待ち，生成された差分（`git diff`）を親エージェントが `main/` ワークツリーへ選択的に統合する．

## 環境変数

| 変数 | 対象 | 説明 |
| :--- | :--- | :--- |
| `WORKER` | `run.sh` | 使用するワーカー（デフォルト: `pi`，利用可能: `pi`, `dsh`, `codewhale`）． |
| `TASK_ID` | `run.sh` | セッション ID を明示してターンをグループ化する（例: `feat-dns`）． |
| `CONTINUE` | `run.sh` | `1` で直前のセッションを継続する． |
| `READ_ONLY` | `run.sh` | `1` で読み取り専用レビューモードにする（`--read-only` と同等，`worker=pi` 専用）． |
| `EXTRA_FLAGS` | `run.sh` | ワーカーに追加で転送するフラグ． |

## プロンプティング原則

### 実装タスクの指示
コーディングワーカーへ渡すプロンプトは，簡潔かつ明確な英語で記述し，以下の制約を満たす:
1. **hush 規約を指示する**: コードコメントに関する規約を指示し，自明な解説コメントの付与を禁じる（"No explanatory or restating comments. Self-documenting naming only."）．
2. **スコープを限定する**: 実装対象外のファイル（ドキュメント等）を編集させない（"Do NOT edit documentation or README files."）．
3. **簡潔な要約を要求する**: 変更内容と根拠の要約箇条書きのみを報告させ，ファイル全文や大きなコードブロックを再掲させない（"Report summary bullets of changes and reasoning only. Do NOT re-print full files or large code blocks."）．

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

### 技術レビュータスクの指示
1. レビュー対象の差分範囲やファイルをプロンプト内で明示する．
2. 技術的観点（NixOS オプションの整合性，systemd ユニット名，権限，障害復旧，セキュリティ）を明確に指定する．

- **改善差分を伴うレビュー（推奨）**:
  一時ワークツリー内でワーカーに直接改善差分を作成させる．
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

- **読み取り専用レビュー（Read-Only）**:
  ```text
  Review Target: <diff range or file paths>
  Focus: <e.g. systemd service definitions, restic restore logic, networking>
  Instructions:
  - Verify that commands, unit names, and Nix options match actual repository configs.
  - Identify edge cases, race conditions, permission issues, or missing steps.
  - Provide concrete suggested fixes with small code snippets only.
  - Report summary bullets of findings and reasoning only. Do NOT re-print full files or large code blocks.
  ```
