---
name: dev-workflow
description: このリポジトリで設定変更を適用するときの手順．変更作業を開始するとき使用する．
---

# 変更・適用手順

1. ブランチ作成とワークツリーの運用:
   - ブランチ作成の判断は [`AGENTS.md`](../../../AGENTS.md) の基本ルールに従う（大きな作業はブランチ，単一パッケージ追加などの軽微な変更は `main` 直接コミット・push 可）．
   - メインツリー（`~/nix-config`）との競合を防ぐため，大きな作業は一時ワークツリー（`.worktrees/<topic-name>/main` または指定ツリー）で実行する．
   ```bash
   git fetch origin main

   # 一時ワークツリーを作成して作業する場合
   git worktree add -b feat/topic-name .worktrees/topic-name/main origin/main

   # 単独ブランチで作業する場合
   git checkout -b feat/topic-name
   ```

2. Nix ファイルや設定ファイルを編集する（実装）．ドキュメントの新規作成・編集は `documentation-guide` スキルに従い，秘密情報は `sops` で編集する（[`secrets/README.md`](../../../secrets/README.md)）．

3. 検証:

   検証コマンド（`pre-commit`, `nix flake check`, `nix build`）は，実行コストとフィードバック速度のトレードオフを考慮して柔軟に使い分ける．

   | 検証コマンド | 実行タイミング / コスト | 特性と検証範囲 |
   | :--- | :--- | :--- |
   | `pre-commit` | コミット時 / 低（数秒） | ファイル単体の静的構文，フォーマット，リント，句読点の検証 |
   | `nix flake check` | 評価時 / 中〜高（数分） | 全ホスト・全成果物の評価（横に広い）．コンパイルは行わず，構文・型・未定義オプションのミスを早期検知 |
   | `nix build`（事前ビルド） | ビルド時 / 状況依存（数秒〜数十分） | 特定ホストの実バイナリ構築（縦に深い）．実依存の取得とビルド成立を確認し，適用時の特権昇格時間を最小化 |

   **判断の思考原則**:
   1. ドキュメント（`docs/`, `*.md`），コメント，スタンドアロンスクリプト等，Nix の Derivation 評価に影響しない変更は，`nix build` も `flake check` も実行しない（コミット時の軽量な pre-commit のみで十分）．
   2. カーネルや巨大なパッケージのコンパイルなど重いビルドが予想される場合は，タイポや構文エラーによる時間の無駄を防ぐため，先に `nix flake check` で構文・型・オプションのミスがないことを素早く確認してから重いビルドに移る．
   3. 既に `nix build` が成功した場合，そのホストの構文・評価・実依存の整合性は実証されているため，ローカルでの重い `nix flake check` を省いて CI に委ねる．手元ホストへの反映が不要で共通基盤（[`flake.nix`](../../../flake.nix) や `lib/`）の変更による全ホストの健全性を手元で確かめたい場合のみ `nix flake check` で全体を薄く広く検証する．
   4. ビルドやチェックがバックグラウンドで実行されている最中にミスを発見してコードを再修正した場合，既存のタスクをキャンセル（kill）してから新しいビルドやチェックを開始する（重複実行の禁止）．

   **実行コマンド**:
   ```bash
   # 全ホストの評価・エラーの早期検知
   nix flake check

   # 設定がビルドできることを確認する場合（事前ビルド）
   nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel --no-link
   ```

   **リンター・チェックツール一覧**:
   | ツール / 検証項目 | 検証内容・ルール |
   | :--- | :--- |
   | `git add -N` / `-A` | Flake 評価対象として未追跡ファイルを事前にステージング |
   | `nixfmt` | ファイル単位でフォーマット検証・整形（`nixfmt <file>`） |
   | `statix` | 同一トップレベルキーの集約定義，空引数の `_:` 指定 |
   | `ysh-check` / `shellcheck` | `*.ysh` は `ysh -n`，`scripts/*.sh` は `shellcheck -x` で検証 |
   | `ja-punctuation` | Markdown（`.md`）の日本語句読点を `，．` に自動補正 |
   | `convco` | コミットメッセージの Conventional Commits 準拠を検証 |
   | `end-of-file-fixer` / `trim-trailing-whitespace` | ファイル末尾改行と末尾空白の整形（強制改行は `<br>` を使用） |

4. レビューと改善:
   変更規模や内容に応じ，技術的検証および文章・ドキュメントのレビューと改善を実施する．
   - 技術的検証では，NixOS イディオムや構文・オプション設定の妥当性，コマンド・サービス名の整合，潜在的不具合やエッジケース，復旧手順の抜け漏れを確認する（外部コーディングワーカーへの技術レビュー委譲は `coding-worker` スキルと [`GEMINI.md`](../../../GEMINI.md) を参照）．
   - 自然言語・ドキュメント・コメント品質では，執筆方針，文体，他ドキュメントとの整合性，相互参照，コード内コメント（`hush` 規約）を確認する（サブエージェントへの文章改善委譲は [`GEMINI.md`](../../../GEMINI.md) を参照）．
   - レビューで判明した問題点や改善事項は，作業ツリー内でコードやドキュメントへ直接反映する．

5. 設定の適用:
   デスクトップ環境（Polkit エージェント稼働ホスト）では，事前承認を得たうえでエージェントが `pkexec` 経由で実行できる:
   ```bash
   pkexec --keep-cwd nixos-rebuild dry-activate --flake .#<hostname>
   pkexec --keep-cwd nixos-rebuild switch --flake .#<hostname>
   ```
   デスクトップ上に Polkit の GUI 認証ダイアログ（実行コマンドが表示される）がポップアップし，ユーザーが指紋認証やパスワード入力で承認する．

   **ビルドと適用の順序（並行実行の禁止）**:
   `nix build`（事前ビルド）と `switch` は**並行実行しない**．必ず一般ユーザー権限でのビルド（`nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel --no-link`）を完了させてから `switch` を実行する．特権昇格時間を最小化し，認証直後に切り替えを完了させ，リソース競合やストアロックを防止する．

   ヘッドレス環境（torii-chan など）・SSH 経由・Polkit が利用できない場合のフォールバックでは，従来どおりユーザー自身が実行する:
   ```bash
   sudo nixos-rebuild dry-activate --flake .#<hostname>
   sudo nixos-rebuild switch --flake .#<hostname>
   ```
   torii-chan へのリモートデプロイ（手動/SBC 用，ユーザー実行）:
   ```bash
   nixos-rebuild switch --flake .#torii-chan-hdd --target-host t3u@10.0.0.1 --sudo --ask-sudo-password --option sandbox false --option filter-syscalls false
   ```

6. コミットとプッシュ（メッセージは英語，Conventional Commits 準拠）:
   ```bash
   git add -A
   git commit -m "feat: topic description"
   git push origin feat/topic-name
   ```
   `main` 直 push は `git push origin main`．

7. PR の作成とマージ（`gh`）:
   ユーザー承認のもと実行する．マージは GitHub PR を作成してリモート上で行う（ローカルマージメッセージは `convco` フックで拒否されるため）．説明文は一時ファイルを作成し `--body-file` で渡す（`--body` はシェル置換で本文が壊れるため使用禁止）．

   **CI（`gh pr checks`）の待機判断**:
   - ローカルで `flake check` や事前ビルドが通っている場合は，リモート CI の完了を待たずにユーザー承認のもと即座にマージ（`gh pr merge --merge --delete-branch`）する．
   - ローカル検証をスキップして CI に委譲した場合は，`gh pr checks`（または `--watch`）で CI のパスを確認してからマージする．

   ```bash
   cat > /tmp/pr-body.md <<'EOF'
   feat: topic description
   ...
   EOF
   gh pr create --title "feat: topic description" --body-file /tmp/pr-body.md
   # ローカル検証済みなら checks を待たずにマージ，CI に委譲した場合のみ完了を確認
   gh pr merge --merge --delete-branch
   ```

   リンクされた一時ワークツリーから `gh pr merge --delete-branch` を実行すると，ブランチチェックアウト中につきローカルブランチ削除の警告が出ることがある．マージ自体は成功しているため，後始末の `git branch -d ... || true` で削除する．

   **メインツリーの同期と後始末**:
   メインツリーへ戻り，用済みの一時ワークツリーを削除した後，空になったタスクディレクトリを削除する（兄弟ワークツリーの一括削除手順は [`GEMINI.md`](../../../GEMINI.md) を参照）:
   ```bash
   cd ~/nix-config
   git worktree remove --force .worktrees/topic-name/main 2>/dev/null || true
   git branch -D feat/topic-name 2>/dev/null || true
   rmdir .worktrees/topic-name 2>/dev/null || true
   ```

   メインツリーの `git status --porcelain` を確認し，状態に応じて手元を同期する:
   - 作業ツリーがクリーンな場合は `git pull origin main` でリモートのマージを同期し，ローカルブランチを削除する（`git branch -d feat/topic-name 2>/dev/null || true`）．
   - 未コミット変更がある場合は pull や checkout を控え，ユーザーへ手動同期を案内する（作業が一段落した際に `git pull` を促す）．

   単独ブランチで作業していた場合は:
   ```bash
   git checkout main
   git pull origin main
   git branch -d feat/topic-name
   ```
