# NixOS 設定構築 - 運用・開発ガイド

全作業エージェント（親オーケストレーター，子ワーカー，サブエージェント）共通の行動規範．手順は `.agents/skills/`，設計仕様は `docs/`，Antigravity ツール運用ルールと親オーケストレーター規範は [`GEMINI.md`](GEMINI.md) を参照．

## 基本ルール

- **ブランチ**: 大きな変更（新ホスト追加，モジュール新設，複数ファイル変更）は `feat/`・`fix/`・`refactor/`・`docs/`・`chore/`・`revert/` トピックブランチで実施する．単一パッケージ追加などの軽微な変更は `main` に直接コミット・push してよい（GitHub Actions の auto-update による `nvfetcher` と [`flake.lock`](flake.lock) の直接コミットを含む）．
- **ブランチ名**: Conventional Commits の型に準拠する．新たな型を追加する場合は [`.github/workflows/nix-check.yml`](.github/workflows/nix-check.yml) の push トリガーも更新する．
- **コミット・PR**: Conventional Commits 準拠．マージは GitHub PR を作成してリモート上で行う（`gh pr merge`．ローカルマージメッセージは `convco` フックで拒否されるため）．
- **ユーザー承認**: `main` へのマージ，リモート `main` への push，`nixos-rebuild switch` の実行（`pkexec` 経由・ユーザー手動実行）は，事前のユーザー承認を必須とする．
- **言語**: ユーザーへの報告は日本語．コード内コメントとコミットメッセージは英語．リポジトリ内ドキュメント（本ファイル・`docs/`・`.agents/`・[`TODO.md`](TODO.md)）は日本語．ルートの [`README.md`](README.md) / [`README.ja.md`](README.ja.md) は常に同期し，サブディレクトリの `README.md` は英語のみとする．日本語文書の句読点は `，．` を厳守する（pre-commit の `ja-punctuation` が全角の読点・句点を自動置換する）．
- **コメント**: `hush` スキル（`~/.agents/skills/hush/`）に従う．自明な解説やコードの言い換えは書かず，名前で意図を表現する．コードのみから意図を読み取れない場合のみ 1〜2 行にとどめる．
- **シェルスクリプト**: 新規スクリプト（Nix 内のインライン生成を含む）は `ysh` スキル（`~/.agents/skills/ysh/`）を参照し **YSH（`.ysh`）** で記述する．レスキュー・インストーラ ISO などの最小環境（例: [`hosts/torii-chan/install-nixos.sh`](hosts/torii-chan/install-nixos.sh)）に限り Bash を使用する．
- **パッケージ実行**: 作業用パッケージは `nix run` または `nix shell` で実行する（ホスト環境への永続インストールは避ける）．
- **レビュー**: 技術的正確性（NixOS イディオム，設定値・サービス名の整合，エッジケース）と文章品質（簡潔な常体，`hush` 規約遵守）を確認する．

## 手順・リファレンス

- **設定変更・適用**: `dev-workflow` スキル
- **ドキュメント執筆・保守**: `documentation-guide` スキル
- **モジュール・パッケージ配置**: `editing-guide` スキル
- **新ホスト追加**: `new-host` スキル（手順詳細は [`docs/operations/adding-a-host.md`](docs/operations/adding-a-host.md)）
- **キャッシュ最適化**: `nix-cache-optimization` スキル
- **YSH スクリプト記述**: `ysh` スキル
- **設計・運用リファレンス**: `docs/`（目次は [`docs/README.md`](docs/README.md)）
- **秘密情報の扱い**: [`docs/operations/secret-management.md`](docs/operations/secret-management.md)（概要は [`secrets/README.md`](secrets/README.md)）
