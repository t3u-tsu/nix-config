# NixOS 設定構築 - 運用・開発ガイド

全エージェント共通の行動規範．手順は `.agents/skills/` および `~/.agents/skills/`，設計仕様は `docs/`，Antigravity (`agy`)固有のツール挙動は [GEMINI.md](GEMINI.md) を参照．

## 基本ルール

- ブランチとワークツリー: 単一パッケージ追加や [flake.lock](flake.lock) / `nvfetcher` 更新などの軽微な変更は `main` に直接コミット・push してよい．それ以外の変更作業 (新ホスト追加，モジュール新設，複数ファイル変更，機能追加，リファクタリング，ドキュメント整備等)はすべて `feat/`・`fix/`・`refactor/`・`docs/`・`chore/`・`revert/` のトピックブランチを切り，必ず専用の一時ワークツリー (`.worktrees/<topic-name>/main`)を作成して作業する (`git worktree add -b <type>/<topic-name> .worktrees/<topic-name>/main origin/main` および `.pre-commit-config.yaml` のシンボリックリンク作成)．メインツリー (`~/nix-config`)上での `git checkout -b` によるブランチ切り替えは行わない (ファイル変更を伴わない事前の読み取り専用調査のみメインツリー上で実行してよい)．
- ブランチ名: Conventional Commits の型に合わせる．新たな型を追加する場合は [.github/workflows/nix-check.yml](.github/workflows/nix-check.yml) の push トリガーも更新する．
- ワーカーとサブエージェントの自律利用: ユーザーの明示的な指示を待たず，外部ワーカー ([.agents/skills/coding-worker/scripts/run.ysh](.agents/skills/coding-worker/scripts/run.ysh) による `pi`, `dsh`, `codewhale`)と内蔵サブエージェント (`invoke_subagent`)を区別せず同列に扱い，自律的にタスクを委譲する．コード実装・リファクタリングに限らず，原因調査，設計検討，ドキュメント執筆，変更後の技術・文章レビューなどあらゆる工程で，親セッションとは異なるモデル (`pi`, `dsh`, `codewhale`)の特性とサブエージェントを組み合わせて品質を高める．1 ファイル数行の軽微な直接編集を除き，親エージェントはワークツリー管理・タスク分割・統合評価・PR 作成の進行役に徹する．
- コミット・PR: Conventional Commits に準拠し，マージは必ず GitHub PR を作成してリモート上で行う (`gh pr merge`．ローカルマージメッセージは `convco` フックで拒否されるため)．
- 承認: `main` へのマージ，リモート `main` への push，`nixos-rebuild switch` の実行 (`pkexec` 経由・ユーザー手動実行)は，事前にユーザーの明示的な承認を必須とする．特に `main` へのマージは，トピックブランチ／PR の設定を手元実機で `switch` して動作確認が完了していることを前提とする．
- 言語: ユーザーへの報告は日本語，コード内コメントとコミットメッセージは英語とする．リポジトリ内ドキュメント (本ファイル・`docs/`・`.agents/`・[TODO.md](TODO.md))は日本語で記述し，句読点は `，．` を厳守する (pre-commit の `ja-punctuation` が全角の読点・句点を自動置換する)．ルートの [README.md](README.md) / [README.ja.md](README.ja.md) は常に同期し，サブディレクトリの `README.md` は英語のみとする．
- コメント: `hush` スキル (`~/.agents/skills/hush/`)に従い，自明な解説やコードの言い換えを書かず名前で意図を表現する．コードのみから意図を読み取れない場合のみ 1〜2 行にとどめる．
- スクリプト言語: 新規スクリプト (Nix 内のインライン生成を含む)は，システム操作・自動化・プロビジョニングは `ysh` スキル (`~/.agents/skills/ysh/`)を参照し **YSH (`.ysh`)** で記述する．テキスト処理・ドキュメント静的検査は **Perl (`.pl`)** で記述する (優先順位: YSH → Perl)．Python スクリプトは新規作成・保守を行わない．レスキュー・インストーラ ISO などの最小環境に限り例外として Bash を使用する．
- パッケージ実行: 本環境には多くのパッケージがインストールされていないため，必要なパッケージは `nix run` または `nix shell` を使って実行する．
- ビルド・評価の排他実行: `nix flake check` や `nix build` は 1 プロセスあたり数 GiB のメモリを消費するため，複数同時に並列実行しない (OOM Kill 誘発防止)．並列ワーカーやサブエージェントを稼働させる場合は，子には軽量な構文検査 (`ysh -n`, `statix`, `nixfmt`, [scripts/docs/check.pl](scripts/docs/check.pl))のみを行わせ，統合評価やビルド検証は親が 1 プロセスずつ直列に実行する．
- レビュー: 技術的正確性 (NixOS イディオム，コマンド・サービス名等の整合性，潜在的不具合，エッジケース)と文章品質 (自然な日本語，他ドキュメントとの整合，`hush` 規約遵守)の双方を確認する．

## 手順・リファレンス

| 目的・領域 | 参照先 |
| :--- | :--- |
| 設定変更・適用手順 | `dev-workflow` スキル ([.agents/skills/dev-workflow/SKILL.md](.agents/skills/dev-workflow/SKILL.md)) |
| ドキュメント執筆・保守 | `documentation-guide` スキル ([.agents/skills/documentation-guide/SKILL.md](.agents/skills/documentation-guide/SKILL.md)) |
| モジュール・パッケージ配置 | `editing-guide` スキル ([.agents/skills/editing-guide/SKILL.md](.agents/skills/editing-guide/SKILL.md)) |
| 新ホスト追加 | `new-host` スキル ([.agents/skills/new-host/SKILL.md](.agents/skills/new-host/SKILL.md)，詳細は [docs/operations/adding-a-host.md](docs/operations/adding-a-host.md)) |
| キャッシュ最適化 | `nix-cache-optimization` スキル ([.agents/skills/nix-cache-optimization/SKILL.md](.agents/skills/nix-cache-optimization/SKILL.md)) |
| 並列エージェント実行 | `dispatching-parallel-agents` スキル (`~/.agents/skills/dispatching-parallel-agents/`) |
| 外部ワーカー委譲 | `coding-worker` スキル ([.agents/skills/coding-worker/SKILL.md](.agents/skills/coding-worker/SKILL.md)) |
| YSH スクリプト記述 | `ysh` スキル (`~/.agents/skills/ysh/`，定義は [home/desktop/dev-tools/ai-tools/skills/ysh/SKILL.md](home/desktop/dev-tools/ai-tools/skills/ysh/SKILL.md)) |
| 設計・運用リファレンス | `docs/` (目次は [docs/README.md](docs/README.md)) |
| 秘密情報の管理 | [docs/operations/secret-management.md](docs/operations/secret-management.md) (概要は [secrets/README.md](secrets/README.md)) |
