---
name: coding-worker
description: >-
  Delegate implementation, refactoring, and technical review tasks to external coding workers (pi, dsh, codewhale, etc.).
  Strictly for Antigravity (Gemini) orchestration — worker agents must NOT invoke this skill.
---

# Coding Worker

外部コーディングワーカー（pi，dsh，codewhale）に対するコード実装・リファクタリングおよび技術レビューの委譲仕様．

## スクリプト仕様

### 1. 実装実行スクリプト (`scripts/run.sh`)

コードの新規作成，編集，リファクタリング，ファイル探索をワーカーに委譲する．

- **基本実行**:
  ```bash
  .agents/skills/coding-worker/scripts/run.sh "<PROMPT_IN_ENGLISH>"
  ```
- **セッション継続**:
  ```bash
  CONTINUE=1 .agents/skills/coding-worker/scripts/run.sh "<FOLLOW_UP_PROMPT>"
  ```
- **セッション ID 指定**:
  ```bash
  TASK_ID="feat-xyz" .agents/skills/coding-worker/scripts/run.sh "<PROMPT_IN_ENGLISH>"
  ```
- **ワーカー切り替え**:
  環境変数 `WORKER` で指定（デフォルト: `pi`，利用可能: `pi`, `dsh`, `codewhale`）．
  ```bash
  WORKER=dsh .agents/skills/coding-worker/scripts/run.sh "<PROMPT_IN_ENGLISH>"
  ```

### 2. 技術レビュースクリプト (`scripts/review.sh`)

Nix 式の整合性，Linux/systemd の動作，エッジケース，障害モードの技術検証をワーカーに委譲する．
レビューアーは作業ツリーの変更を禁止された制約下で動作するが，`nix eval` の実行や外部リファレンスの確認などの調査コマンドは制限なく実行可能である（実行前後の作業ツリー差分チェックにより改変を検知・防止する）．

- **差分レビュー**:
  ```bash
  DIFF_RANGE="origin/main..HEAD" .agents/skills/coding-worker/scripts/review.sh "<REVIEW_FOCUS_IN_ENGLISH>"
  ```
- **ファイル指定レビュー**:
  ```bash
  FILES="docs/operations/backup-and-restore.md" .agents/skills/coding-worker/scripts/review.sh "<REVIEW_FOCUS_IN_ENGLISH>"
  ```
- **ワーカー指定**:
  ```bash
  WORKER=dsh DIFF_RANGE="origin/main..HEAD" .agents/skills/coding-worker/scripts/review.sh "<REVIEW_FOCUS_IN_ENGLISH>"
  ```

## プロンプティング原則

### 実装タスクの指示
コーディングワーカーへ渡すプロンプトは，以下の制約を満たす英語で記述する:
1. **英語で指示する**: プロンプトは簡潔かつ明確な英語で作成する．
2. **hush 規約を指示する**: コードコメントに関する規約を指示し，自明な解説コメントの付与を禁じる（"No explanatory or restating comments. Self-documenting naming only."）．
3. **スコープを限定する**: 実装対象外のファイル（ドキュメント等）を編集させない（"Do NOT edit documentation or README files."）．

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
1. レビュー対象のファイルや差分範囲（`DIFF_RANGE`，`FILES`）を明示する．
2. 技術的観点（NixOS オプションの整合性，systemd ユニット名，権限，障害復旧，セキュリティ）を明確に指定する．

```text
Review Target: <diff range or file paths>
Focus: <e.g. systemd service definitions, restic restore logic, networking>
Instructions:
- Verify that commands, unit names, and Nix options match actual repository configs.
- Identify edge cases, race conditions, permission issues, or missing steps.
- Provide concrete suggested fixes with code snippets.
```
