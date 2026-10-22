# Antigravity 共通運用ルール

Antigravity エージェントのツール運用ルールおよび親オーケストレーターの行動規範．

## ツール運用とプロセス監視（全エージェント共通）

- **タイマーポーリング禁止**: コマンドやプロセスの完了待ちに `schedule` による小刻みなタイマー監視を行わない．完了通知で自動再開されるため，ツール呼び出しを停止して待つ．
- **外部プロセス待機**: バックグラウンドプロセスの待機は，タイマーではなく `tail --pid=<PID> -f /dev/null` などの単一コマンドで一度だけ完了通知を受ける．

## 親オーケストレーター行動規範

> **子エージェント（サブエージェント）の適用除外**: `invoke_subagent` で起動された子セッションは本章以降をすべて無視する．指示された作業ディレクトリ内で具体的タスクに専念し `send_message` で親へ報告する（ワークツリー作成や再帰起動は禁止）．

親セッションはオーケストレーターとして全体の進行管理・設計・タスク分解・差分統合を担当する．外部ワーカー起動時は `coding-worker` スキル（`run.ysh`），検証・適用時は `dev-workflow` スキルを参照．

### 1. 親オーケストレーターの行動境界（初動判定）

コンテキスト汚染防止と並列性最大化のため，深追いを避け即座に委譲する．

- **親が直接実行**: Git 操作（ワークツリー管理・差分統合），進行管理，ユーザー対話．
- **外部ワーカーへ委譲（`coding-worker`）**: コード実装・技術レビュー（専用ツリーを展開し，改善差分を直接作成させる．`pi`, `dsh`, `codewhale`）．
- **サブエージェントへ委譲（`self` / `research`）**: 横断的調査・原因究明（ワーカー `--read-only` も可），ドキュメント改修・推敲，文章レビュー．

### 2. 並列優先・自律委任の原則

- **並列分割・排他スコープ**: 複数ファイル・モジュール・独立タスクにまたがる作業は，ディレクトリ・ファイル（日英対訳等）・検証単位で排他的に分割し，直列化せず並列投入する（ワーカー・サブエージェント混成可）．
- **自律委任（指示最小化）**: 子には本ルールや管理手順，過度なコード片を渡さず，ゴール・担当スコープ・制約のみを指定して**具体設計・編集は子に委ねる**．
- **非同期・逐次合流**: 投入直後に停止せず先行作業を進める．待機時も全完了を待たず，**いずれか 1 つ完了した時点で即座に再開し，先行完了したツリーから順次統合・検証を進める（未完了タスクと統合作業のオーバーラップ）**．
- **状態分離**: 兄弟ツリーごとに Git インデックスおよびワーカー状態（セッション・ログ）が独立するため，並列稼働や対話継続でもロック競合やコンテキスト混同は起きない．

### 3. 兄弟ワークツリー統合ライフサイクル

1. **ツリー一括作成**: 同一トピック配下にフラットな兄弟ワークツリーを一括作成する（実装・ドキュメントだけでなくレビュー用も展開）．
   ```bash
   git fetch origin main
   git worktree add -b feat/<topic> .worktrees/<topic>/main origin/main # 統合用
   git worktree add -b feat/<topic>-worker-a .worktrees/<topic>/worker-a origin/main
   git worktree add -b feat/<topic>-worker-b .worktrees/<topic>/worker-b origin/main
   git worktree add -b docs/<topic>-subagent-c .worktrees/<topic>/subagent-c origin/main
   ```
2. **並列一括投入**: 兄弟ツリーを作業ディレクトリ（`Cwd`）とし，ワーカー（待機せず連続起動）やサブエージェント（`Subagents` 配列）を一斉投入する．
   ```bash
   # ワーカー並列投入（Cwd: 各兄弟ツリー）※完了を待たずに連続起動
   TASK_ID="worker-a" .agents/skills/coding-worker/scripts/run.ysh "Task A: ..."
   TASK_ID="worker-b" .agents/skills/coding-worker/scripts/run.ysh "Task B: ..."
   # 追加指示・対話継続（CONTINUE=1 と TASK_ID で特定タスク継続，直前継続は CONTINUE=1 単独）
   CONTINUE=1 TASK_ID="worker-a" .agents/skills/coding-worker/scripts/run.ysh "Fix: ..."
   ```
   ```json
   {
     "Subagents": [
       {"Role": "Docs Editor", "TypeName": "self", "Prompt": "作業ディレクトリ: ...\n担当: docs/...\nゴール: ...\n完了報告: send_message"},
       {"Role": "Comment Reviewer", "TypeName": "self", "Prompt": "作業ディレクトリ: ...\n担当: modules/...\nゴール: hush 精査\n完了報告: send_message"}
     ]
   }
   ```
3. **先行推進・逐次合流待機**: 投入直後も PR 下書き（`/tmp/pr-body.md`）作成や先行確認を進める．作業完了後はツール呼び出しを停止して待機し，**いずれか 1 つ完了通知を受けた時点で即座に再開する**．
4. **差分統合・検証（インクリメンタル統合）**: 完了した兄弟ツリーから順次パッチを統合用ツリーへ適用し，他タスク完了を待たずに先行検証（ビルド，`nix flake check` 等）を進める．
   ```bash
   git -C .worktrees/<topic>/worker-a add -N . # 未追跡ファイルを diff に含める
   git -C .worktrees/<topic>/worker-a diff HEAD --binary | git -C .worktrees/<topic>/main apply
   ```
5. **コミット・PR 作成・後始末**: 全差分の統合・検証後，統合用ツリーからコミット，push（`git push -u origin <branch>`），PR 作成（`gh pr create --title <title> --body-file /tmp/pr-body.md`）を行う．完了後に兄弟ツリー群および一時ブランチを一括削除する．
   ```bash
   for wt in .worktrees/<topic>/*; do [ "$wt" != ".worktrees/<topic>/main" ] && git worktree remove --force "$wt" 2>/dev/null || true; done
   git worktree remove --force .worktrees/<topic>/main 2>/dev/null || true
   rmdir .worktrees/<topic> 2>/dev/null || true
   git branch -D feat/<topic>-worker-a feat/<topic>-worker-b docs/<topic>-subagent-c 2>/dev/null || true
   ```
