# NixOS 設定構築 - 運用・開発ガイド

すべての作業エージェント（親オーケストレーター，子ワーカー，サブエージェント）に適用される共通ルール．共通の手順は `.agents/skills/`，設計リファレンスは `docs/` に分離している．Antigravity 共通のツール運用ルールおよび親オーケストレーターの行動規範は `GEMINI.md` を参照する．

## 基本ルール

- **ブランチ**: 大きな作業（新ホスト追加，モジュール新設，複数ファイルの変更）は `feat/`・`fix/`・`refactor/`・`docs/`・`chore/`・`revert/` のブランチで行う．パッケージ 1 つ追加などの軽微な変更は `main` に直接コミット・push してよい．GitHub Actions の auto-update による `nvfetcher` と `flake.lock` の `main` 直接コミットは例外とする．
- **ブランチ名**: Conventional Commits の型に合わせる．新たな型を追加する場合は `.github/workflows/nix-check.yml` の push 対象も更新する．
- **言語**: ユーザーへの報告は日本語．コードコメントとコミットメッセージは英語．エージェント運用ドキュメント（本ファイル・`docs/`・`.agents/`・`TODO.md`）は日本語．ルートの `README.md` / `README.ja.md` は常に同期して更新し，サブディレクトリの `README.md` は英語のみ．日本語文書の句読点は `，．` を使う（pre-commit の ja-punctuation が全角の読点・句点を自動置換する）．
- **コメント**: `hush` スキル（`~/.agents/skills/hush/`）に従う．自明なコメントやコードの言い換えコメントは書かず，名前で表現する．コードのみでは意図を読み取れない場合のみ 1〜2 行にとどめる．
- **シェルスクリプト**: 新規に作成するシェルスクリプト（Nix 内のインライン生成を含む）は，原則として `ysh` スキル（`~/.agents/skills/ysh/`）を参照し **YSH（`.ysh`）** で記述する．ただし，レスキュー・インストーラ ISO 内で動く最小構成の環境（例: `hosts/torii-chan/install-nixos.sh`）などでは例外として Bash を使用する．
- **コミット・PR**: Conventional Commits 準拠．Git のデフォルトローカルマージメッセージは `convco` フックで拒否されるため，マージは必ず GitHub PR を作成してリモート上で行う（`gh pr merge`）．
- **レビュー**: 変更やドキュメントの検証・レビューでは，技術的検証（NixOS イディオム，コマンド・サービス名等の整合性，潜在的不具合，エッジケース）と，自然言語・文章品質（自然な日本語，他ドキュメントとの整合性，`hush` 規約に沿ったコメント精査）の双方を確認する．
- **承認**: `main` へのマージ，リモート `main` へのプッシュ，`nixos-rebuild switch` の実行（エージェントによる `pkexec` 経由，ユーザーによる手動実行のいずれも）は，事前にユーザーの明示的な承認を必須とする．
- **パッケージ実行**: 本環境には多くのパッケージがインストールされていないため，必要なパッケージは `nix run` / `nix shell` を使って実行する．

## 手順・リファレンス

- **設定変更・適用**: `dev-workflow` スキル
- **ドキュメント執筆・保守**: `documentation-guide` スキル
- **モジュール・パッケージ配置**: `editing-guide` スキル
- **新ホスト追加**: `new-host` スキル（詳しい手順は `docs/operations/adding-a-host.md`）
- **キャッシュ最適化**: `nix-cache-optimization` スキル
- **YSH スクリプト記述**: `ysh` スキル
- **設計・運用リファレンス**: `docs/`（目次は `docs/README.md`）
- **秘密情報の扱い**: `docs/operations/secret-management.md`（概要は `secrets/README.md`）
