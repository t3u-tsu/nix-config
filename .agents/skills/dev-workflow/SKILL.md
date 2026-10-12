---
name: dev-workflow
description: このリポジトリで設定変更を適用するときの手順．変更作業を開始するとき使用する．
---

# 変更・適用手順

1. **ブランチ作成とワークツリーの運用**:
   - ブランチを作成するかどうかは AGENTS.md の基本ルールに従う（大きな作業はブランチ，パッケージ1つ追加のような小さな変更は `main` に直接コミット・push してよい）．
   - **ワークツリーの利用**: メインツリー（`~/nix-config`）での作業と競合しないよう，大きな作業では一時ワークツリー（`.worktrees/<topic-name>/main` や指定された作業ツリー）で作業を行う．作業者は割り当てられたディレクトリで作業を開始する．
   - ※ 親オーケストレーターによるタスク分解，兄弟ワークツリー管理，並列実行，先行作業の進行，および差分統合の手順は `orchestration` スキルを参照する．
   - **作成・切り替えコマンド**:
     ```bash
     git fetch origin main

     # 一時ワークツリーを作成して作業する場合
     git worktree add -b feat/topic-name .worktrees/topic-name/main origin/main

     # 単独ブランチで作業する場合
     git checkout -b feat/topic-name
     ```

2. **実装**: Nix ファイルや設定ファイルを編集する．ドキュメントの新規作成・編集時は `documentation-guide` スキルに従う．秘密情報は `sops` で編集する（`secrets/README.md`）．

3. **検証**

   検証コマンド（`pre-commit`, `nix flake check`, `nix build`）は，**実行コストとフィードバック速度のトレードオフ**を考慮して柔軟に使い分ける．

   - **各コマンドの特性**:
     - **pre-commit** (`git commit` 時): 低コスト（数秒）．ファイル単体の静的構文，フォーマット，リント，句読点を検証．
     - **`nix flake check`**: 中〜高コスト（数分）．**横に広い（全ホスト・全成果物の評価）**．コンパイルは行わず，構文・型・未定義オプションのミスを早期に検知する．
     - **`nix build` (事前ビルド)**: 状況依存（数秒〜数十分）．**縦に深い（特定ホストの実バイナリ構築）**．実依存の取得とビルドの成立を確認し，適用時の特権昇格時間を最小化する．

   - **判断の思考原則**:
     1. **Nix 評価空間に影響しない変更なら，検証をスキップする**:
        ドキュメント（`docs/`, `*.md`），コメント，スタンドアロンスクリプト等，Nix の Derivation 評価に影響を与えない変更は，`nix build` も `flake check` も実行しない（コミット時の軽量な pre-commit のみで十分）．
     2. **重いビルドが予想される場合は，先に `flake check` で早期検知する**:
        カーネルや巨大なパッケージのコンパイルなど，`nix build` に長時間を要すると予想される場合，事前の確認なくビルドを実行するとタイポや構文エラーで数十分が無駄になる．先に `nix flake check` を実行し，構文・型・オプションのミスがないことを素早く確認してから重いビルドに移る．
     3. **二重検証を避ける（CI への委譲）**:
        既に `nix build` が成功した場合，そのホストの構文・評価・実依存の整合性は実証されているため，ローカルで重ねて重い `nix flake check` を実行しない（全ホスト回帰確認は GitHub Actions の CI に委ねる）．逆に，手元ホストへの反映は不要だが共通基盤（`flake.nix` や `lib/`）の変更で全ホストの健全性を手元ですぐ確かめたい場合は，個別の `nix build` ではなく `flake check` で全体を薄く広く検証する．
     4. **古いビルド・チェックの即時停止**:
        ビルドやチェックがバックグラウンドで実行されている最中にミスを発見してコードを再修正した場合，**必ず先に既存のタスクをキャンセル（kill）してから新しいビルドやチェックを開始する**．古いタスクを放置したまま再ビルドを重複して走らせてはならない．

   - **実行コマンド**:
     ```bash
     # 全ホストの評価・エラーの早期検知
     nix flake check

     # 設定がビルドできることを確認する場合（事前ビルド）
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
     - ※ 外部コーディングワーカーへの技術レビュー委譲の詳細は `coding-worker` スキルおよび `GEMINI.md` を参照する．

   - **自然言語・ドキュメント・コメント品質の観点**:
     ドキュメントの執筆方針，文体，他ドキュメントとの整合性，相互参照，およびコード内コメント（`hush` 規約）の品質観点は，すべて `documentation-guide` スキルに従う（サブエージェントへの文章改善委譲の詳細は `GEMINI.md` を参照）．

   - **改善の反映**:
     レビューで判明した問題点や改善事項は，作業ツリー内でコードやドキュメントへ直接反映する．
     ※ 兄弟ワークツリーからの差分統合や管理手順は `orchestration` スキルを参照する．

5. **適用**:
   デスクトップ環境（Polkit エージェントが動作している x1c7 など）では，事前にユーザーの承認を得たうえで，エージェントが `pkexec` 経由で実行できる:
   ```bash
   pkexec --keep-cwd nixos-rebuild dry-activate --flake .#<hostname>
   pkexec --keep-cwd nixos-rebuild switch --flake .#<hostname>
   ```
   実行するとデスクトップ上に Polkit の GUI 認証ダイアログ（実行コマンドが表示される）がポップアップし，ユーザーが指紋認証やパスワード入力で承認・認証を行う．

   **ビルドと適用の順序（並行実行の禁止）**:
   `nix build`（事前ビルド）と `switch` は**絶対に並行実行しない**．`nix build` は特権昇格の時間を最小限に抑えるための前準備であるため，必ず一般ユーザー権限でのビルド（`nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel --no-link`）を完了させてから `switch` を実行する．これにより認証直後に切り替えが完了し，リソース競合やストアロックも防止できる．

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
   # ローカル検証済みなら checks を待たずにマージ，CI に委譲した場合のみ完了を確認
   gh pr merge --merge --delete-branch
   ```

   **一時ワークツリー内での `--delete-branch`**:
   リンクされた一時ワークツリーから `gh pr merge --delete-branch` を実行すると，ブランチが当該ワークツリーでチェックアウト中のためローカルブランチを削除できず警告が出ることがある．マージ自体は成功しているため，後始末の `git branch -d ... || true` で削除する．

   **メインツリーの同期と後始末**:
   - **一時ワークツリーの後始末**:
     メインツリーへ戻り，用済みの一時ワークツリーを削除した後，空になったタスクディレクトリを削除する:
     ```bash
     cd ~/nix-config
     # 一時ワークツリーの削除
     git worktree remove --force .worktrees/topic-name/main 2>/dev/null || true
     git branch -D feat/topic-name 2>/dev/null || true

     # 空になったタスクディレクトリの削除
     rmdir .worktrees/topic-name 2>/dev/null || true
     ```
     ※ 兄弟ワークツリーの一括削除手順は `orchestration` スキルを参照する．
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
