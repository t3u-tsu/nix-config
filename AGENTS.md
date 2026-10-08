# NixOS 設定構築 - 運用・開発ガイド

エージェント作業のルール．手順は `.agents/skills/`，設計リファレンスは `docs/` に分離している．

## 基本ルール

- **ブランチ**: 大きな作業（新ホスト追加，モジュール新設，複数ファイルの変更）は `feat/`・`fix/`・`refactor/`・`docs/`・`chore/` のブランチで行う．パッケージ1つ追加のような小さな変更は `main` に直接コミット・push してよい．GitHub Actions の auto-update が `nvfetcher` と `flake.lock` を `main` へ直接コミットするのは例外．
- **ブランチ名**: Conventional Commits の型に合わせる．新たな型を追加する場合は `.github/workflows/nix-check.yml` の push 対象も更新する．
- **言語**: ユーザーへの報告は日本語．コードコメントとコミットメッセージは英語．エージェント運用ドキュメント（本ファイル・`docs/`・`.agents/`・`TODO.md`）は日本語．ルートの `README.md` / `README.ja.md` は常に同期して更新し，サブディレクトリの `README.md` は英語のみ．日本語文書の読点・句点は `，．` を使う（pre-commit の ja-punctuation が全角の読点・句点を自動置換する）．
- **コメント**: `hush` スキル（`~/.agents/skills/hush/`）に従う．自明なコメントやコードの言い換えコメントは書かず，名前で表現する．コードのみでは意図を読めない場合のみ1〜2行付ける．
- **コミット・PR**: Conventional Commits 準拠．Git のデフォルトローカルマージメッセージは `convco` フックで拒否されるため，マージは必ず GitHub PR を作成してリモート上で行う（`gh pr merge`）．
- **レビュー**: 変更やドキュメントの検証・レビューは強みに応じて分担する．Codewhale（DeepSeek）は技術的検証（NixOS イディオム，コマンド・systemd 整合性，潜在的不具合，エッジケース）を担当し，Antigravity サブエージェント（Gemini）は自然言語・文章品質（自然な日本語，句読点 `，．`，SSOT 整合性，`hush` ルールによるコメント精査）を担当する．
- **承認**: `main` へのマージ，リモート `main` へのプッシュ，`nixos-rebuild switch` の実行（エージェントによる `pkexec` 経由，ユーザーによる手動実行のいずれも）は実行前にユーザーの明示的な承認が必要．
- **パッケージ実行**: 本環境には `python3` などが未インストールのため，必要なパッケージは `nix run` / `nix shell` を使う．

## 手順・リファレンス

- **設定変更・適用**: `dev-workflow` スキル
- **ドキュメント執筆・保守**: `documentation-guide` スキル
- **モジュール・パッケージ配置**: `editing-guide` スキル
- **新ホスト追加**: `new-host` スキル（正本手順は `docs/operations/adding-a-host.md`）
- **キャッシュ最適化**: `nix-cache-optimization` スキル
- **Codewhale 委譲**: `codewhale-worker` スキル
- **設計・運用リファレンス**: `docs/`（目次は `docs/README.md`）
- **秘密情報の扱い**: `docs/operations/secret-management.md`（概要は `secrets/README.md`）
