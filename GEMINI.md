# Antigravity (`agy`) 固有行動ルール

Antigravity エージェント固有のツール呼び出し仕様と非同期実行時の振る舞いを定義する．リポジトリ共通の開発規約は [AGENTS.md](AGENTS.md) を参照．

## 1. ワークツリー作成とワーカー・サブエージェントの自律ディスパッチ (指示待ちの禁止)

- トピックブランチを切る変更作業 (`main` 直コミット対象の単一パッケージ追加等を除く全変更)を開始する際は，ファイル編集や書き込み系ワーカー起動の前に必ず一時ワークツリー (`.worktrees/<topic-name>/main`)を作成し，`.pre-commit-config.yaml` をシンボリックリンクする ([.agents/skills/dev-workflow/SKILL.md](.agents/skills/dev-workflow/SKILL.md) 参照)．メインツリー (`~/nix-config`)上で `git checkout -b` を実行したり，ブランチ作業分のファイルをメインツリーで直接編集したりしない (ブランチ作成前の読み取り専用調査のみメインツリー上で実行可)．
- ユーザーからワーカーやサブエージェントの利用を明示指示されなくても，コード実装・リファクタリング・原因調査・設計検証・ドキュメント執筆・変更後レビューの各工程で，外部ワーカー ([.agents/skills/coding-worker/scripts/run.ysh](.agents/skills/coding-worker/scripts/run.ysh) による `pi`, `dsh`, `codewhale`)と内蔵サブエージェント (`invoke_subagent`)を区別せず同列の手段として自律的にディスパッチする．Gemini 以外のモデルの特性を積極的に組み合わせるため，作業開始時に `coding-worker` スキル ([.agents/skills/coding-worker/SKILL.md](.agents/skills/coding-worker/SKILL.md))および `dispatching-parallel-agents` スキル (`~/.agents/skills/dispatching-parallel-agents/`)を参照する．
- 独立した複数ファイルの変更や調査は，同一ターン (1 レスポンス)内で複数の `run_command` (`WaitMsBeforeAsync: 500`)または `invoke_subagent` を同時発行して並列実行する (`run.ysh` と `invoke_subagent` の混在並列も可．1 ターンに 1 つずつ呼び出すと直列実行になる)．ただし `run.ysh --read-only` (`worker=pi` 専用)は実行前後のツリー状態変化を検査するため，ファイル編集を行うワーカーとは同時実行せず，事前調査時または編集完了後のレビュー段階で並列実行する．
- `run_command` やサブエージェントは親セッションの初期作業ディレクトリ (`~/nix-config`)を起点とするため，一時ワークツリー内で作業させる場合は `run_command` の先頭に `cd .worktrees/<topic-name>/main && ...` を明記し，`invoke_subagent` のプロンプトにも作業ディレクトリ (`.worktrees/<topic-name>/main`)と対象ファイルパスを明示する．
- `invoke_subagent` で起動された子エージェントは，指示された作業ディレクトリ内の担当スコープに専念して `send_message` で親へ報告し，自身で新規ワークツリーの作成や `run.ysh` の再帰起動を行わない．

## 2. 非同期実行と先行進行・先行報告 (待機ブロックの禁止)

- `nix flake check`，`nix build`，外部ワーカー ([.agents/skills/coding-worker/scripts/run.ysh](.agents/skills/coding-worker/scripts/run.ysh))など数秒以上を要するコマンドは，`run_command` の `WaitMsBeforeAsync: 500` を指定して即座にバックグラウンド化し，フロントで同期ブロックしない (ただし `nix flake check` や `nix build` 自体は [AGENTS.md](AGENTS.md) に従い直列に 1 プロセスずつ実行し，複数同時に起動しない)．
- コマンドをバックグラウンド起動した直後は，完了を待たずに残りの独立した工程 (ドキュメント更新，`/tmp/pr-body.md` の作成，別ファイルの確認など)をそのまま先行して進める．
- 進めるべき別作業がすべて完了し，バックグラウンド処理やサブエージェントの完了待ちのみとなった場合は，「待機します」の一言だけで済ませず，その時点で完了している作業・変更内容の報告を先にすべて書き切り，「現在バックグラウンドで `<処理内容>` を実行中です．完了次第，結果を報告します」と添えてターンを終了する (ユーザーへ直接応答する親セッションのみ．サブエージェントは担当タスク完了後に `send_message` で報告する)．

## 3. イベント駆動待機 (ポーリング禁止)

- バックグラウンドタスクやサブエージェントの完了待ちに `schedule` によるタイマー監視や `manage_task` のステータスポーリングを行わない．ツール呼び出しを終了すれば完了通知で自動再開される．
- `run_command` 管理外の既存 OS プロセス (別ターミナルで起動済みのジョブ等)の終了を待つ必要がある場合に限り，`tail --pid=<PID> -f /dev/null` (`WaitMsBeforeAsync: 500`)の単一コマンドで一度だけ完了通知を受ける．
