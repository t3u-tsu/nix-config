# Antigravity (`agy`) 固有行動ルール

Antigravity エージェント固有のツール呼び出し仕様と非同期実行時の振る舞いを定義する．リポジトリ共通の開発規約は [AGENTS.md](AGENTS.md) を参照．

## 1. 非同期実行と先行進行・先行報告 (待機ブロックの禁止)

- `nix flake check`，`nix build`，外部ワーカー ([.agents/skills/coding-worker/scripts/run.ysh](.agents/skills/coding-worker/scripts/run.ysh))など数秒以上を要するコマンドは，`run_command` の `WaitMsBeforeAsync: 500` を指定して即座にバックグラウンド化し，フロントで同期ブロックしない．
- コマンドをバックグラウンド起動した直後は，完了を待たずに残りの独立した工程 (ドキュメント更新，`/tmp/pr-body.md` の作成，別ファイルの確認など)をそのまま先行して進める．
- 進めるべき別作業がすべて完了し，バックグラウンド処理の完了待ちのみとなった場合は，「待機します」とだけ出力して止まるのではなく，**その時点で今回の変更内容・確認事項の報告を先にすべて書き切り，「現在バックグラウンドで `<コマンド>` を実行中です．完了次第，結果を報告します」と添えてターンを終了する**．

## 2. イベント駆動待機 (ポーリング禁止)

- バックグラウンドタスクやサブエージェントの完了待ちに `schedule` によるタイマー監視や `manage_task` のステータスポーリングを行わない．ツール呼び出しを終了すれば完了通知で自動再開される．
- 外部プロセスの完了待機が必要な場合は，`tail --pid=<PID> -f /dev/null` などの単一コマンドで一度だけ完了通知を受ける．

## 3. 並列ディスパッチ時のツール発行仕様

- ユーザーから並列実行やワーカー・サブエージェントの利用を指示された場合は，作業前に `dispatching-parallel-agents` スキル (`~/.agents/skills/dispatching-parallel-agents/`)および `coding-worker` スキル ([.agents/skills/coding-worker/SKILL.md](.agents/skills/coding-worker/SKILL.md))を参照する．
- 並列実行時は**必ず同一ターン (1 レスポンス)内で複数の `invoke_subagent` または `run_command` (`WaitMsBeforeAsync: 500`)を同時に発行する** (1 ターンに 1 つずつ呼び出すと直列実行になる)．
- `run_command` は毎回リポジトリルートから新しいシェルで実行されるため，ワークツリー内で実行する場合はコマンド先頭に `cd <worktree> && ...` を明記する．
