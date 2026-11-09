# Antigravity (`agy`) 固有行動ルール

Antigravity エージェント固有のツール呼び出し仕様と非同期実行時の振る舞いを定義する．リポジトリ共通の開発規約は [AGENTS.md](AGENTS.md) を参照．

## 1. 非同期実行と先行進行・先行報告 (待機ブロックの禁止)

- `nix flake check`，`nix build`，外部ワーカー ([.agents/skills/coding-worker/scripts/run.ysh](.agents/skills/coding-worker/scripts/run.ysh))など数秒以上を要するコマンドは，`run_command` の `WaitMsBeforeAsync: 500` を指定して即座にバックグラウンド化し，フロントで同期ブロックしない (ただし `nix flake check` や `nix build` 自体は [AGENTS.md](AGENTS.md) に従い直列に 1 プロセスずつ実行し，複数同時に起動しない)．
- コマンドをバックグラウンド起動した直後は，完了を待たずに残りの独立した工程 (ドキュメント更新，`/tmp/pr-body.md` の作成，別ファイルの確認など)をそのまま先行して進める．
- 進めるべき別作業がすべて完了し，バックグラウンド処理やサブエージェントの完了待ちのみとなった場合は，「待機します」の一言だけで済ませず，その時点で完了している作業・変更内容の報告を先にすべて書き切り，「現在バックグラウンドで `<処理内容>` を実行中です．完了次第，結果を報告します」と添えてターンを終了する (ユーザーへ直接応答する親セッションのみ．サブエージェントは担当タスク完了後に `send_message` で報告する)．

## 2. イベント駆動待機 (ポーリング禁止)

- バックグラウンドタスクやサブエージェントの完了待ちに `schedule` によるタイマー監視や `manage_task` のステータスポーリングを行わない．ツール呼び出しを終了すれば完了通知で自動再開される．
- `run_command` 管理外の既存 OS プロセス (別ターミナルで起動済みのジョブ等)の終了を待つ必要がある場合に限り，`tail --pid=<PID> -f /dev/null` (`WaitMsBeforeAsync: 500`)の単一コマンドで一度だけ完了通知を受ける．

## 3. 並列ディスパッチ時のツール発行仕様

- ユーザーから並列実行やワーカー・サブエージェントの利用を指示された場合は，作業前に `dispatching-parallel-agents` スキル (`~/.agents/skills/dispatching-parallel-agents/`)および `coding-worker` スキル ([.agents/skills/coding-worker/SKILL.md](.agents/skills/coding-worker/SKILL.md))を参照する．
- 並列実行時は必ず同一ターン (1 レスポンス)内で複数の `invoke_subagent` または `run_command` (`WaitMsBeforeAsync: 500`)を同時に発行する (1 ターンに 1 つずつ呼び出すと直列実行になる)．
- `run_command` やサブエージェントは毎回リポジトリルート (`/home/t3u/nix-config`)を起点とするため，ワークツリー内で作業させる場合は `run_command` の先頭に `cd <worktree> && ...` を明記し，`invoke_subagent` のプロンプトにも作業ディレクトリと対象ファイルパスを明示する．
- `invoke_subagent` で起動された子エージェントは，指示された作業ディレクトリ内の担当スコープに専念して `send_message` で親へ報告し，自身で新規ワークツリーの作成や `run.ysh` の再帰起動を行わない．
