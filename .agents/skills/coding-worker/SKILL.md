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

```text
Task: <goal>
Target files: <list of files>
Instructions: <concise steps>
Constraints:
- No explanatory or obvious comments. Self-documenting naming only.
- Do NOT edit documentation or README files.
- Follow nixpkgs conventions and formatting.
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
  ```

- **読み取り専用レビュー（Read-Only）**:
  ```text
  Review Target: <diff range or file paths>
  Focus: <e.g. systemd service definitions, restic restore logic, networking>
  Instructions:
  - Verify that commands, unit names, and Nix options match actual repository configs.
  - Identify edge cases, race conditions, permission issues, or missing steps.
  - Provide concrete suggested fixes with code snippets.
  ```
