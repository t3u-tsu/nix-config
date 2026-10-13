# Antigravity 共通運用ルール

本リポジトリで Antigravity を用いて稼働するエージェントに適用されるツール運用ルール，および親オーケストレーター専用の行動規範である．

## ツール運用とプロセス監視（全エージェント共通）

不要なツール再実行やトークン消費を抑えるため，以下のルールを遵守する．

- **小刻みなタイマー監視の禁止**:
  コマンドやプロセスの完了待ちに `schedule` タイマーによるポーリングを行わない．バックグラウンド通知やタスク完了メッセージによって自動的に処理が再開されるため，ツールの呼び出しを停止して完了通知を待つ．
- **バックグラウンドプロセスの待機**:
  バックグラウンドで実行中の外部プロセスを監視・待機する必要がある場合は，小刻みなタイマーではなく `tail --pid=<PID> -f /dev/null` などの単一コマンドで一度だけ完了通知を受け取る．

## 親オーケストレーターとしての行動規範

ユーザーと直接対話し，全体の進行管理・アーキテクチャ設計・統合を行う親セッションとして振る舞う場合は以下に従う．作業開始時にまず本ファイルを確認し，外部ワーカー起動時は `coding-worker` スキル（`run.ysh` の引数・制約），検証・適用時は `dev-workflow` スキルを参照する．

※ `invoke_subagent` により起動されたサブエージェント（子）は，親向け行動規範（セクション 1〜3）をすべて無視し，指示された具体的タスクに専念する．ワークツリー作成やプロセスの再帰起動は禁止とし，自身の担当作業のみを遂行して `send_message` で親へ報告する．

### 1. 親オーケストレーターの行動境界

親セッションは全体の進行管理・アーキテクチャ設計・タスク分解・差分統合に専念し，作業の性質に応じて適切に委譲する．親自身のコンテキスト汚染を防ぎ並列性を活かすため，深追いを避ける．

- **コード実装・技術レビュー**: 本格的なコード作成・編集や技術レビューは，原則として兄弟ワークツリーを展開して外部コーディングワーカー（`pi`, `dsh`, `codewhale`）へ委譲する（`coding-worker` スキル参照）．レビュー時も専用ツリーを切り，指摘のみにとどめず改善差分を直接作成させる（推奨）．例外として，1〜2 ファイルの特定箇所の軽微な修正（typo 修正，設定値変更等）に限り，親自身が直接編集してよい．
- **コード調査・探索**: 親は 1〜2 ステップのピンポイントな局所確認（ディレクトリ・ファイルの存在確認，grep 1 回，定義確認等）のみを担当する．3 ファイル以上の横断精査，ログ精査，不具合原因究明，複数方針の比較検討などの探索的調査は，親が深追いせずサブエージェント（`research` / `self`）やワーカー（`run.ysh --read-only`）へ委譲する．
- **ドキュメント・推敲・レビュー**: ドキュメント改修，文章推敲，`hush` 規約に沿ったコメント精査，および文章品質レビューはサブエージェント（`self`）へ委譲する．レビュー時も専用ツリーを展開し，改善点があれば直接編集させて差分を残す（1〜2 行程度の軽微な修正は親自身が直接行ってよい）．

### 2. 並列優先・自律委任・非同期パイプライン

- **並列優先・分割指針**: 変更・調査対象が 2 つ以上のファイル，モジュール，独立タスクにまたがる本格的な作業は，単一処理に直列化せず原則として並列に分割・投入する．分割単位はディレクトリ・領域単位，ファイル単位（`README.md` / `README.ja.md` 対訳同期等），または独立検証単位とし，排他スコープを割り当てる（1〜2 ファイルの軽微な修正や局所確認は除く）．
- **自律委任（コンテキスト最小化）**: 子エージェントには本ルールや管理手順を読ませず，コード片や推敲文案を具体的に詰め込みすぎない．「達成すべきゴール」「排他的な担当スコープ」「守るべき制約」の 3 点のみを直接渡し，具体設計や編集詳細は自律的に委ねる．過度な具体化は指示コストを増やし，子の自律的な推論を妨げる．
- **排他指定の徹底**: 各エージェントに担当スコープを排他指定する．兄弟ツリーにより作業中の物理的な衝突は起きないが，統合ツリーへマージ・パッチ適用する際のコンフリクト回避と責務明確化のために徹底する．
- **非同期パイプライン**: バックグラウンド投入直後にツール呼び出しを停止しない．先行作業（PR 下書き作成，ピンポイント先行確認，追加タスク投入）を推進し，合流ポイント（全タスク完了後の統合段階）まで待機しない．
- **状態分離**: 兄弟ツリーごとに Git インデックスと `.agents/skills/coding-worker/.state/`（セッション・ログ）が独立するため，並列稼働してもロック競合やセッション混同は起きない．`CONTINUE=1` による対話継続も他ワーカーと干渉しない（詳細は `coding-worker` スキル）．

### 3. 兄弟ワークツリー統合ライフサイクル

タスクは以下のライフサイクルに従って進行・統合する．

1. **ツリー一括作成**: メインツリーの手元作業を保護するため，同一トピック配下にフラットな兄弟ワークツリーを一括作成する（実装・ドキュメント作成だけでなく，レビュー時も専用ツリーを展開する）．
   ```bash
   git fetch origin main
   git worktree add -b feat/<topic> .worktrees/<topic>/main origin/main # 統合用
   git worktree add -b feat/<topic>-worker-a .worktrees/<topic>/worker-a origin/main
   git worktree add -b docs/<topic>-subagent-b .worktrees/<topic>/subagent-b origin/main
   git worktree add -b test/<topic>-worker-review .worktrees/<topic>/worker-review origin/main # レビュー・改善用
   ```
2. **並列一括投入**: 兄弟ツリーを作業ディレクトリ（`Cwd`）とし，ワーカーやサブエージェント（`Subagents` 配列）を一斉起動する．原則として `pi` を使用し，`dsh` や `codewhale` はタスク特性に応じて選択する．ワーカー・サブエージェント双方のレビュータスクも専用ツリーで起動し，指摘にとどまらず改善差分を直接作成させる（統合手戻り防止）．
   ```bash
   # ワーカー起動例 (Cwd: .worktrees/<topic>/worker-a)
   .agents/skills/coding-worker/scripts/run.ysh "Task: ..."
   # 追加指示・対話継続時
   CONTINUE=1 .agents/skills/coding-worker/scripts/run.ysh "Fix: ..."
   ```
   ```json
   {
     "Subagents": [
       {"Role": "Docs Editor", "TypeName": "self", "Prompt": "作業ディレクトリ: ...\n担当: docs/...\nゴール: ...\n制約: 常体，句読点 `，．`\n完了報告: send_message"},
       {"Role": "Comment Reviewer", "TypeName": "self", "Prompt": "作業ディレクトリ: ...\n担当: modules/...\nゴール: hush 精査\n制約: hush 規約準拠\n完了報告: send_message"}
     ]
   }
   ```
3. **先行推進・合流待機**: 投入後も PR 下書き（`/tmp/pr-body.md`: 概要・主な変更点・検証項目）の作成やピンポイント先行確認を進める．先行タスクの完了に依存しない後続作業があれば別ツリーを作成して追加投入する．サブエージェントは完了時に `send_message` で親へ報告する．先行作業が尽きた段階でのみツールの呼び出しを停止して完了通知を待つ．
4. **差分統合・検証**: 各兄弟ツリーからパッチを抽出し，統合用ツリーへ適用する．
   ```bash
   # 未追跡ファイルを diff に含めるため事前に add -N
   git -C .worktrees/<topic>/worker-a add -N .
   git -C .worktrees/<topic>/worker-a diff HEAD --binary | git -C .worktrees/<topic>/main apply
   # または新規ディレクトリ等の同期: rsync -av --exclude='.git' .worktrees/<topic>/worker-a/<dir>/ .worktrees/<topic>/main/<dir>/
   ```
   適用後，`dev-workflow` スキルに従い統合ツリー内でビルドや `nix flake check` などの検証を実施する．
5. **コミット・PR 作成・後始末**: 統合用ツリーからコミット，push（`git push -u origin <branch>`），PR 作成（`gh pr create --title <title> --body-file /tmp/pr-body.md`）を行う．マージまたは作業完了後，兄弟ツリー群および一時ブランチを一括削除する．
   ```bash
   for wt in .worktrees/<topic>/*; do [ "$wt" != ".worktrees/<topic>/main" ] && git worktree remove --force "$wt" 2>/dev/null || true; done
   git worktree remove --force .worktrees/<topic>/main 2>/dev/null || true
   rmdir .worktrees/<topic> 2>/dev/null || true
   git branch -D feat/<topic>-worker-a docs/<topic>-subagent-b 2>/dev/null || true
   ```
