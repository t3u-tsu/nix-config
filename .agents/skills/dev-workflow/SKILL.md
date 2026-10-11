---
name: dev-workflow
description: このリポジトリで設定変更を適用するときの手順．変更作業を開始するとき使用する．
---

# 変更・適用手順

1. **ブランチ作成**: ブランチを切るかは AGENTS.md の基本ルールに従う．切る場合は `git checkout -b feat/topic-name`．

2. **実装**: Nix ファイルや設定ファイルを編集する．秘密情報は `sops` で編集する（`secrets/README.md`）．

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
        カーネルや巨大なパッケージのコンパイルなど，`nix build` に長時間を要すると予想される場合，いきなりビルドを回すとタイポや構文エラーで数十分が無駄になる．先に `nix flake check`（あるいは eval チェック）を実行し，構文・型・オプションのミスがないことを素早く確認してから重いビルドに移る．
     3. **二重検証を排除する（包括関係と CI 委譲）**:
        既に `nix build` が成功した場合，そのホストの構文・評価・実依存の整合性は実証されているため，ローカルで重ねて重い `nix flake check` を回さない（全ホスト回帰確認は GitHub Actions の CI に委ねる）．逆に，手元ホストへの反映は不要だが共通基盤（`flake.nix` や `lib/`）の変更で全ホストの健全性を手元ですぐ確かめたい場合は，個別の `nix build` ではなく `flake check` で全体を薄く広く検証する．
     4. **先行タスクの破棄原則（古いビルド・チェックの即時停止）**:
        ビルドやチェックがバックグラウンドで実行されている最中にミスを発見してコードを再修正した場合，**必ず先に既存のタスクをキャンセル（kill）してから新しいビルドやチェックを開始する**．古いタスクを放置したまま再ビルドを重複して走らせてはならない．

   - **実行コマンド**:
     ```bash
     # 全ホスト評価・ポカミス早期検知（フェイルファスト）
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
     - shellcheck は `scripts/*.sh` が対象で `-x` 付き（`nebula-lib.sh` の source を追う）．
     - ja-punctuation は `.md` が対象．**日本語文書の句読点は `，．` を使う**（他の句読点はフックが自動置換する）．
     - convco はコミットメッセージの Conventional Commits 準拠を検証する．
     - end-of-file-fixer は全テキストファイルの末尾改行を揃える．`_sources/generated.{json,nix}` は nvfetcher の生成物なので除外している．
     - trim-trailing-whitespace は行末の空白を落とす．Markdown の行末スペース2つは改行の意味を持つため，改行したい場合は `<br>` を使う．

4. **レビュー**:
   変更規模や内容に応じて，Codewhale と Antigravity サブエージェントの強みを活かしてレビューを実施する．
   - **技術レビュー（Codewhale 委譲）**:
     コードや設定の論理，NixOS イディオム，ドキュメント記載コマンドや systemd ユニット名の正確性，潜在的不具合を検証する．
     ```bash
     # 差分全体の技術レビュー
     DIFF_RANGE="origin/main..HEAD" .agents/skills/codewhale-worker/scripts/review.sh
     # 特定ファイルの技術レビュー
     FILES="docs/operations/backup-and-restore.md" .agents/skills/codewhale-worker/scripts/review.sh
     ```
   - **自然言語・ドキュメント・コメントレビュー（Antigravity サブエージェント）**:
     日本語文書の自然さ，句読点 `，．`，SSOT 原則の遵守，相互参照リンクの正確性，および `hush` ルールに基づく自明なコメントの排除をサブエージェントにレビューさせる．

5. **適用**:
   デスクトップ環境（Polkit エージェントが動作している x1c7 など）では，事前にユーザーの承認を得たうえで，エージェントが `pkexec` 経由で実行できる:
   ```bash
   pkexec --keep-cwd nixos-rebuild dry-activate --flake .#<hostname>
   pkexec --keep-cwd nixos-rebuild switch --flake .#<hostname>
   ```
   実行するとデスクトップ上に Polkit の GUI 認証ダイアログ（実行コマンドが表示される）がポップアップし，ユーザーが指紋認証やパスワード入力で承認・認証を行う．

   **ビルドと適用の順序（並行実行の禁止）**:
   `nix build`（事前ビルド）と `switch` は**絶対に並行実行しない**．`nix build` は特権昇格の保留時間を最小化するための「前準備（ステージング）」であるため，必ず一般ユーザー権限でのビルド（`nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel --no-link`）を完了させてから `switch` を実行する．これにより，ユーザーの認証直後に瞬時に切り替えが完了し，リソース競合やストアロックも防止できる．

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
   git checkout main
   git pull origin main
   git branch -d feat/topic-name  # ローカルブランチの後始末
   ```
