# NixOS 設定構築 - 運用・開発ガイド

すべての作業エージェント（親オーケストレーター，子ワーカー，サブエージェント）に適用される共通ルール．共通の手順は `.agents/skills/`，設計リファレンスは `docs/` に分離している．Antigravity 共通のツール運用ルールおよび親オーケストレーターの行動規範は `GEMINI.md` を参照する．

## 基本ルール

- **ブランチ**: 大きな作業（新ホスト追加，モジュール新設，複数ファイルの変更）は `feat/`・`fix/`・`refactor/`・`docs/`・`chore/`・`revert/` のトピックブランチで行う．パッケージ 1 つ追加などの軽微な変更は `main` に直接コミット・push してよい（GitHub Actions の auto-update による `nvfetcher` と `flake.lock` の直接コミットも同様）．
- **ブランチ名**: Conventional Commits の型に準拠する．新たな型を追加する場合は `.github/workflows/nix-check.yml` の push トリガーも更新する．
- **コミット・PR**: Conventional Commits 準拠．Git デフォルトのローカルマージメッセージ（`Merge branch ...`）は `convco` フックで拒否されるため，マージは必ず GitHub PR を作成してリモート上で行う（`gh pr merge`）．
- **ユーザー承認の徹底**: `main` へのマージ，リモート `main` への push，および `nixos-rebuild switch` の実行（`pkexec` 経由・ユーザー手動実行の双方）は，事前にユーザーの明示的な承認を必須とする．
- **言語**: ユーザーへの報告は日本語．コード内コメントとコミットメッセージは英語．リポジトリ内ドキュメント（本ファイル・`docs/`・`.agents/`・`TODO.md`）は日本語．ルートの `README.md` / `README.ja.md` は常に同期させ，サブディレクトリの `README.md` は英語のみとする．日本語文書の句読点は `，．` を厳守する（pre-commit の `ja-punctuation` が全角の読点・句点を自動置換する）．
- **コメント**: `hush` スキル（`~/.agents/skills/hush/`）に従う．自明なコメントやコードの言い換えコメントは書かず，名前で意図を表現する．コードのみでは意図を読み取れない場合のみ 1〜2 行にとどめる．
- **シェルスクリプト**: 新規スクリプト（Nix 内のインライン生成を含む）は，原則として `ysh` スキル（`~/.agents/skills/ysh/`）を参照し **YSH（`.ysh`）** で記述する．ただし，レスキュー・インストーラ ISO 内などの最小環境（例: `hosts/torii-chan/install-nixos.sh`）に限り例外として Bash を使用する．
- **パッケージ実行**: 作業に必要なパッケージはホスト環境に常用インストールせず，`nix run` または `nix shell` を用いてオンデマンドで実行する．
- **レビューと品質検証**: 変更やドキュメントの検証・レビューでは，技術的正確性（NixOS イディオム，コマンド・サービス名の整合，エッジケース，潜在不具合）と，文章品質（自然な日本語，他ドキュメントとの整合性，`hush` 規約の遵守）の双方を確認する．

## 手順・リファレンス

- **設定変更・適用**: `dev-workflow` スキル
- **ドキュメント執筆・保守**: `documentation-guide` スキル
- **モジュール・パッケージ配置**: `editing-guide` スキル
- **新ホスト追加**: `new-host` スキル（詳細な手順は `docs/operations/adding-a-host.md`）
- **キャッシュ最適化**: `nix-cache-optimization` スキル
- **YSH スクリプト記述**: `ysh` スキル
- **設計・運用リファレンス**: `docs/`（目次は `docs/README.md`）
- **秘密情報の扱い**: `docs/operations/secret-management.md`（概要は `secrets/README.md`）
