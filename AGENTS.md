# NixOS 設定構築 - 運用・開発ガイド

全作業エージェント (親オーケストレーター，子ワーカー，サブエージェント)共通の行動規範．手順は `.agents/skills/`，設計仕様は `docs/`，Antigravity ツール運用ルールと親オーケストレーター規範は [GEMINI.md](GEMINI.md) を参照．

## 基本ルール

- ブランチ: 大きな作業 (新ホスト追加，モジュール新設，複数ファイル変更)は `feat/`・`fix/`・`refactor/`・`docs/`・`chore/`・`revert/` のトピックブランチで実施する．単一パッケージ追加などの軽微な変更は `main` に直接コミット・push してよい (GitHub Actions の auto-update による `nvfetcher` と [flake.lock](flake.lock) の直接コミットを含む)．
- ブランチ名: Conventional Commits の型に合わせる．新たな型を追加する場合は [.github/workflows/nix-check.yml](.github/workflows/nix-check.yml) の push トリガーも更新する．
- コミット・PR: Conventional Commits に準拠し，マージは必ず GitHub PR を作成してリモート上で行う (`gh pr merge`．ローカルマージメッセージは `convco` フックで拒否されるため)．
- 承認: `main` へのマージ，リモート `main` への push，`nixos-rebuild switch` の実行 (`pkexec` 経由・ユーザー手動実行)は，事前にユーザーの明示的な承認を必須とする．
- 言語: ユーザーへの報告は日本語，コード内コメントとコミットメッセージは英語とする．リポジトリ内ドキュメント (本ファイル・`docs/`・`.agents/`・[TODO.md](TODO.md))は日本語で記述し，句読点は `，．` を厳守する (pre-commit の `ja-punctuation` が全角の読点・句点を自動置換する)．ルートの [README.md](README.md) / [README.ja.md](README.ja.md) は常に同期し，サブディレクトリの `README.md` は英語のみとする．
- コメント: `hush` スキル (`~/.agents/skills/hush/`)に従い，自明な解説やコードの言い換えを書かず名前で意図を表現する．コードのみから意図を読み取れない場合のみ 1〜2 行にとどめる．
- スクリプト言語: 新規スクリプト (Nix 内のインライン生成を含む)は，システム操作・自動化・プロビジョニングは `ysh` スキル (`~/.agents/skills/ysh/`)を参照し **YSH (`.ysh`)** で記述する．テキスト処理・ドキュメント静的検査は **Perl (`.pl`)** で記述する (優先順位: YSH → Perl)．Python スクリプトは新規作成・保守を行わない．レスキュー・インストーラ ISO などの最小環境 (例: [hosts/torii-chan/install-nixos.sh](hosts/torii-chan/install-nixos.sh))に限り例外として Bash を使用する．
- パッケージ実行: 本環境には多くのパッケージがインストールされていないため，必要なパッケージは `nix run` または `nix shell` を使って実行する．
- レビュー: 技術的正確性 (NixOS イディオム，コマンド・サービス名等の整合性，潜在的不具合，エッジケース)と文章品質 (自然な日本語，他ドキュメントとの整合，`hush` 規約遵守)の双方を確認する．

## 手順・リファレンス

| 目的・領域 | 参照先 |
| :--- | :--- |
| 設定変更・適用手順 | `dev-workflow` スキル |
| ドキュメント執筆・保守 | `documentation-guide` スキル |
| モジュール・パッケージ配置 | `editing-guide` スキル |
| 新ホスト追加 | `new-host` スキル (手順詳細は [docs/operations/adding-a-host.md](docs/operations/adding-a-host.md)) |
| キャッシュ最適化 | `nix-cache-optimization` スキル |
| YSH スクリプト記述 | `ysh` スキル |
| 設計・運用リファレンス | `docs/` (目次は [docs/README.md](docs/README.md)) |
| 秘密情報の管理 | [docs/operations/secret-management.md](docs/operations/secret-management.md) (概要は [secrets/README.md](secrets/README.md)) |
