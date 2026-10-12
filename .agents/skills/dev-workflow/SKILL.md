---
name: dev-workflow
description: このリポジトリで設定変更を適用するときの手順．変更作業を開始するとき使用する．
---

# 変更・適用手順

1. **ブランチ作成・一時ワークツリー運用（並列・パイプライン型ライフサイクル）**:
   - ブランチを作成するかどうかは AGENTS.md の基本ルールに従う（パッケージ1つ追加のような小さな変更は `main` に直接コミット・push してよい）．
   - **タスク名前空間とフラットな兄弟ワークツリー構造**:
     メインツリー（`~/nix-config`）の手元作業と衝突しないよう，また作業規模（単一作業か並列・委譲作業か）にかかわらず常に一貫した構造を保つため，タスク名前空間として常に `.worktrees/<topic-name>/` を使用し，その配下に起点・統合・PR用ワークツリーとして `main/`（`.worktrees/<topic-name>/main`）を作成する．
     複数モジュール改修やドキュメント改訂などで外部ワーカー（`pi`, `dsh`）やサブエージェントを並行稼働させる場合は，同じ名前空間配下にフラットな兄弟ワークツリー（`worker-*`，`subagent-*`）を展開する．

     ```text
     .worktrees/<topic-name-1>/main           # 起点・統合・PR用ワークツリー
                              /worker-pi-1    # 兄弟ワークツリー（ワーカー1用）
                              /worker-dsh-2   # 兄弟ワークツリー（ワーカー2用）
                              /subagent-docs  # 兄弟ワークツリー（サブエージェント用）
     .worktrees/<topic-name-2>/main           # 別タスクのワークツリー
     ```

   - **並列・パイプライン型ワークフローの5フェーズ**:
     独立したタスクを直列に処理せず，バッチ一括投入と先行進行（パイプライン化）によって効率を最大化する．単一タスクの場合も「兄弟ツリーが1つまたはなし」の特殊ケースとして同一の流れで扱う．

     - **フェーズ1: タスク分解と複数兄弟ワークツリーの一括準備**
       変更対象が複数ファイル，複数モジュール，またはコードとドキュメントのように異なるドメインにまたがる場合，独立した作業単位に分解する（目安: 2ファイルまたは2モジュール以上で原則並列化）．
       起点となる統合用ワークツリー `main/` を作成し，同時に必要な兄弟ワークツリー群（`worker-*`, `subagent-*`）を一括作成する:
       ```bash
       git fetch origin main

       # 起点・統合・PR用の親ワークツリー
       git worktree add -b feat/topic-name .worktrees/topic-name/main origin/main

       # 複数ワーカー・サブエージェント用の兄弟ワークツリーを一括作成
       git worktree add -b feat/topic-name-worker-pi-1 .worktrees/topic-name/worker-pi-1 origin/main
       git worktree add -b feat/topic-name-worker-dsh-2 .worktrees/topic-name/worker-dsh-2 origin/main
       git worktree add -b feat/topic-name-subagent-docs .worktrees/topic-name/subagent-docs origin/main
       ```
       ※ 単一タスク（親エージェント単独作業）の場合は `main/` のみ，単一ワーカー委譲の場合は `main/` と単一の `worker-*` のみを作成する．一時ワークツリーを使用しない単独ブランチ運用の場合は `git checkout -b feat/topic-name`．

     - **フェーズ2: 並列一括投入（非同期バッチ起動）**
       各兄弟ワークツリーに対し，対応する外部ワーカーやサブエージェントを**1回のターンで一斉にバックグラウンド投入**する．1つ起動して結果を待ってから次を起動する直列実行は避け，並行可能な処理はすべて最初に一括起動する:
       - **サブエージェント**: `invoke_subagent` ツールの `Subagents: [...]` 配列に複数エージェントを同時に指定して一括起動する．
       - **外部コーディングワーカー**: `run_command`（`WaitMsBeforeAsync` 指定）で各ワークツリーを `Cwd` に設定し，バックグラウンドプロセスとして並行起動する（`WORKER=pi ./scripts/worker/run.ysh ...` や `WORKER=dsh ./scripts/worker/run.ysh ...`）．

     - **フェーズ3: 先行進行（非同期パイプライン化）**
       並列投入したワーカーやサブエージェントの完了を待たずに，親エージェントができる作業を先先と進める．
       - PR 本文ドラフト（`/tmp/pr-body.md` 等）の事前起草．
       - 後続のビルド・検証計画の準備や，別ドメインの依存関係・設定調査．
       - 統合用 `main/` ワークツリーで親エージェントが担当する静的変更（メタデータ更新，小さな共通設定等）の実装．
       - 後続の合流フェーズで必要な統合スクリプトや確認手順の整理．

     - **フェーズ4: 同期ポイント（Join Point）**
       親エージェントの先行作業が完了し，各ワーカー・サブエージェントの成果物を統合・検証・ビルドしなければ次へ進めない段階（合流ポイント）に至って初めてツールの呼び出しを停止し，完了通知を待つ．
       小刻みなタイマー監視やポーリングは行わず，バックグラウンドプロセスの完了通知やサブエージェントからのメッセージ受信により自動起床する．

     - **フェーズ5: 選択的差分統合・検証と一括後始末**
       完了通知を受け取った後，各兄弟ワークツリーの変更を精査（`git diff`）し，妥当な成果物のみを `main/` ワークツリーへ選択的に取り込む（手順4参照）．
       統合後に一括して検証（手順3参照）を実施し，問題がなければ用済みの兄弟ワークツリー群を一括削除してコミット・PR 作成へ進む．

   - **利点**:
     1. **最大のスループット**: タスク分解と非同期バッチ投入により，複数の変更を同時並行で進行できる．
     2. **待ち時間の極小化**: ワーカーの処理待ち時間を親エージェントの先行作業（パイプライン化）に充てることで，全体のリードタイムを短縮できる．
     3. **安全な分離と取捨選択**: ワークツリーが完全に分離されているためコンフリクトせず，各ツリーの差分を精査して良い変更のみを選択的に統合できる．
     4. **構造の一貫性**: 単一タスクから大規模並列タスクまで同一の名前空間・ディレクトリ構造で扱え，作業規模の変化に応じて柔軟にスケールできる．
     5. **セッション分離**: 別のタスクが並行稼働していても，`.worktrees/<topic-name>/` ごとに完全に分離されて手元作業と衝突しない．

2. **実装**: Nix ファイルや設定ファイルを編集する．ドキュメントの新規作成・編集時は `documentation-guide` スキルに従う．秘密情報は `sops` で編集する（`secrets/README.md`）．

3. **検証**

   検証コマンド（`pre-commit`, `nix flake check`, `nix build`）は，**実行コスト（時間・リソース）とフィードバック速度（フェイルファスト）のトレードオフ**を考慮して柔軟に使い分ける．

   - **各コマンドの特性**:
     - **pre-commit** (`git commit` 時): 極小コスト（数秒）．ファイル単体の静的構文，フォーマット，リント，句読点を検証．
     - **`nix flake check`**: 中〜高コスト（数分）．**横に広い（全ホスト・全成果物の評価）**．コンパイルは行わず，構文・型・未定義オプションのミスを早期検知（フェイルファスト）する．
     - **`nix build` (事前ビルド)**: 状況依存（数秒〜数十分）．**縦に深い（特定ホストの実バイナリ構築）**．実依存の取得・ビルド成立を実証し，特権昇格時間を極小化する（ステージング）．

   - **判断の思考原則**:
     1. **Nix 評価空間に影響しない変更なら，検証をスキップする**:
        ドキュメント（`docs/`, `*.md`），コメント，スタンドアロンスクリプト等，Nix の Derivation 評価に影響を与えない変更は，`nix build` も `flake check` も実行しない（コミット時の軽量な pre-commit のみで十分）．
     2. **重いビルドが予想される場合は，先に `flake check` でフェイルファストする**:
        カーネルや巨大なパッケージのコンパイルなど，`nix build` に長時間を要すると予想される場合，事前の確認なくビルドを実行するとタイポや構文エラーで数十分が無駄になる．先に `nix flake check` を実行し，構文・型・オプションのミスがないことを素早く確認してから重いビルドに移る．
     3. **二重検証を排除する（包括関係と CI 委譲）**:
        既に `nix build` が成功した場合，そのホストの構文・評価・実依存の整合性は実証されているため，ローカルで重ねて重い `nix flake check` を実行しない（全ホスト回帰確認は GitHub Actions の CI に委ねる）．逆に，手元ホストへの反映は不要だが共通基盤（`flake.nix` や `lib/`）の変更で全ホストの健全性を手元ですぐ確かめたい場合は，個別の `nix build` ではなく `flake check` で全体を薄く広く検証する．
     4. **先行タスクの破棄原則（古いビルド・チェックの即時停止）**:
        ビルドやチェックがバックグラウンドで実行されている最中にミスを発見してコードを再修正した場合，**必ず先に既存のタスクをキャンセル（kill）してから新しいビルドやチェックを開始する**．古いタスクを放置したまま再ビルドを重複して走らせてはならない．

   - **実行コマンド**:
     ```bash
     # 全ホスト評価・基本的なエラー早期検知（フェイルファスト）
     nix flake check

     # 設定がビルドできることを確認する場合（事前ビルド・ステージング）
     nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel --no-link
     ```
     - Flake は git 追跡下のファイルのみを参照するため，新規作成・変更ファイルは事前に `git add -A`（または `git add -N`）しておく必要がある．
     - 個別に nixfmt を実行する場合は**ファイル単位**で指定する:
       ```bash
       nixfmt --check <file>
       nixfmt <file>
       ```
     - statix: 同じトップレベルキーはまとめて attrset で定義し，分割して記述しない．引数が空の場合は `{ ... }:` ではなく `_:` を使用する．
     - ysh-check は `\.ysh$` を対象に YSH 構文を検証する（`ysh -n`）．shellcheck は `scripts/*.sh` が対象．
     - ja-punctuation は `.md` が対象．**日本語文書の句読点は `，．` を使う**（他の句読点はフックが自動置換する）．
     - convco はコミットメッセージの Conventional Commits 準拠を検証する．
     - end-of-file-fixer は全テキストファイルの末尾改行を揃える．`_sources/generated.{json,nix}` は nvfetcher の生成物なので除外している．
     - trim-trailing-whitespace は行末の空白を落とす．Markdown の行末スペース2つは改行の意味を持つため，改行したい場合は `<br>` を使う．

4. **レビューと改善**:
   変更規模や内容に応じて，技術的検証および自然言語・ドキュメントのレビューと改善を実施する．
   - **技術的検証の観点**:
     - NixOS のイディオムや構文・オプション設定が適切か．
     - コマンド，サービス名，systemd ユニット名がリポジトリ内の実設定やシステム仕様と整合しているか．
     - 潜在的な不具合，競合，権限不足，エッジケース，復旧時の手順抜けがないか．
     - ※ Antigravity による外部コーディングワーカーへの技術レビュー・改善差分委譲の詳細は `coding-worker` スキルおよび `GEMINI.md` を参照する．

   - **自然言語・ドキュメント・コメント品質の観点**:
     ドキュメントの執筆方針，文体，SSOT 整合性，相互参照，およびコード内コメント（`hush` 規約）の品質観点・レビュー基準は，すべて `documentation-guide` スキル（SSOT）に従う（Antigravity によるサブエージェントへの文章改善委譲の詳細は `GEMINI.md` を参照）．

   - **作業ツリーからの差分統合と後始末**:
     独立した兄弟ワークツリー群（`.worktrees/<topic-name>/worker-*`，`subagent-*` 等）で並行作業を行った場合，各ツリーから未コミット変更を含めて差分を取得し，起点・統合用ワークツリー（`main/`）へ選択的に取り込むか，作業ツリー内でコミットしてからマージする．
     新規作成ファイル（未追跡ファイル）が差分やコミットから漏れないよう，パッチ抽出前には `git add -N .`，コミット時には `git add -A` を使用する:
     ```bash
     # main/ ワークツリーに移動
     cd .worktrees/topic-name/main

     # 各作業ツリーの差分を確認（新規作成ファイルを diff に含めるため add -N . を実行）
     git -C ../worker-pi-1 add -N .
     git -C ../worker-pi-1 diff

     # main/ ワークツリーに取り込む場合（パッチ適用: 新規作成ファイルも含めて抽出）
     git -C ../worker-pi-1 add -N .
     git -C ../worker-pi-1 diff | git apply

     # 別の兄弟ツリーの差分も順次適用
     git -C ../worker-dsh-2 add -N .
     git -C ../worker-dsh-2 diff | git apply

     # または作業ツリー内でコミットしてからマージする場合（add -A で新規作成ファイルも含めてコミット）
     git -C ../worker-pi-1 add -A && git -C ../worker-pi-1 commit -m "feat(module-a): ..."
     git merge --squash feat/topic-name-worker-pi-1

     # 検証・統合完了後に兄弟ワークツリー群を一括後始末
     cd ~/nix-config
     for wt in .worktrees/topic-name/worker-* .worktrees/topic-name/subagent-*; do
       [ -d "$wt" ] || continue
       branch=$(git -C "$wt" branch --show-current 2>/dev/null || true)
       git worktree remove --force "$wt"
       [ -n "$branch" ] && git branch -D "$branch" 2>/dev/null || true
     done
     ```

5. **適用**:
   デスクトップ環境（Polkit エージェントが動作している x1c7 など）では，事前にユーザーの承認を得たうえで，エージェントが `pkexec` 経由で実行できる:
   ```bash
   pkexec --keep-cwd nixos-rebuild dry-activate --flake .#<hostname>
   pkexec --keep-cwd nixos-rebuild switch --flake .#<hostname>
   ```
   実行するとデスクトップ上に Polkit の GUI 認証ダイアログ（実行コマンドが表示される）がポップアップし，ユーザーが指紋認証やパスワード入力で承認・認証を行う．

   **ビルドと適用の順序（並行実行の禁止）**:
   `nix build`（事前ビルド）と `switch` は**絶対に並行実行しない**．`nix build` は特権昇格の保留時間を最小化するための「前準備（ステージング）」であるため，必ず一般ユーザー権限でのビルド（`nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel --no-link`）を完了させてから `switch` を実行する．これにより，ユーザーの認証直後に切り替えが完了し，リソース競合やストアロックも防止できる．

   ヘッドレス環境（torii-chan など）・SSH 経由・Polkit が利用できない場合のフォールバックでは，従来どおりユーザー自身が実行する:
   ```bash
   sudo nixos-rebuild dry-activate --flake .#<hostname>
   sudo nixos-rebuild switch --flake .#<hostname>
   ```
   torii-chan へのリモートデプロイ（手動/SBC 用，ユーザー実行）:
   ```bash
   nixos-rebuild switch --flake .#torii-chan-hdd --target-host t3u@10.0.0.1 --sudo --ask-sudo-password --option sandbox false --option filter-syscalls false
   ```

6. **コミットとプッシュ**（メッセージは英語，Conventional Commits 準拠）
   ```bash
   git add -A
   git commit -m "feat: topic description"
   git push origin feat/topic-name
   ```
   `main` 直 push は `git push origin main`．

7. **PR（`gh`）**: ユーザー承認のうえ実行する．Git デフォルトのローカルマージコミットメッセージ（`Merge branch ...`）は `convco` フックで拒否されるため，マージは必ず GitHub PR を作成してリモート上で行う．説明文は一時ファイルに書いて `--body-file` で渡す．`--body` にバッククォート等を含めるとシェルがコマンド置換して本文が壊れるため使わない．

   **CI（`gh pr checks`）の待機判断**:
   - **ローカルで `flake check` や事前ビルドが通っている場合**: リモート CI の完了を待つ必要はなく，ユーザー承認のもと即座にマージ（`gh pr merge --merge --delete-branch`）してよい．
   - **ローカル検証をスキップして CI に委譲した場合**: `gh pr checks`（または `--watch`）で CI のパスを確認してからマージする．

   ```bash
   cat > /tmp/pr-body.md <<'EOF'
   feat: topic description
   ...
   EOF
   gh pr create --title "feat: topic description" --body-file /tmp/pr-body.md
   # ローカル検証済みなら checks を待たずにマージ，CI委譲時のみ完了を確認
   gh pr merge --merge --delete-branch
   ```

   **一時ワークツリー内での `--delete-branch`**:
   リンクされた一時ワークツリーから `gh pr merge --delete-branch` を実行すると，ブランチが当該ワークツリーでチェックアウト中のためローカルブランチを削除できず警告が出ることがある．マージ自体は成功しているため，後始末の `git branch -d ... || true` で削除する．

   **メインツリーの同期と後始末**:
   - **一時ワークツリーの後始末**:
     メインツリーへ戻り，残っている兄弟ワークツリー群（`worker-*`，`subagent-*` 等）があれば `--force` で一括削除して作業ブランチを片付け，統合用の `main` ワークツリーを削除した後，空になった親ディレクトリ（タスク名前空間）を削除する:
     ```bash
     cd ~/nix-config
     # 兄弟ワークツリー群の一括削除（存在する場合，ブランチも合わせて削除）
     for wt in .worktrees/topic-name/worker-* .worktrees/topic-name/subagent-*; do
       [ -d "$wt" ] || continue
       branch=$(git -C "$wt" branch --show-current 2>/dev/null || true)
       git worktree remove --force "$wt"
       [ -n "$branch" ] && git branch -D "$branch" 2>/dev/null || true
     done

     # 統合用 main ワークツリーの削除
     git worktree remove --force .worktrees/topic-name/main 2>/dev/null || true
     git branch -D feat/topic-name 2>/dev/null || true

     # タスク名前空間ディレクトリの削除
     rmdir .worktrees/topic-name
     ```
   - **メインツリーの手元同期（安全確認）**:
     メインツリーの `git status --porcelain` を確認する．
     - **Clean な場合**: `git pull origin main` を実行してリモートのマージを同期し，その後ローカルブランチを削除する:
       ```bash
       git pull origin main
       git branch -d feat/topic-name 2>/dev/null || true
       ```
     - **Dirty な場合（手元作業中）**: メインツリーでの pull や checkout を控え，ユーザーへ「リモートへのマージが完了しました．現在手元に未コミットの変更があるため，作業が一段落した際に git pull を実行してください」と報告する．手動 pull 後にローカルブランチが不要であれば削除する．
   - 単独ブランチで作業していた場合は:
     ```bash
     git checkout main
     git pull origin main
     git branch -d feat/topic-name
     ```
