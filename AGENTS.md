# NixOS 設定構築 - 運用・開発ガイド

エージェント作業のルール．手順は `.codewhale/skills/`，設計リファレンスは `docs/` に分離している．

## 基本ルール

- **ブランチ**: 大きな作業（新ホスト追加，モジュール新設，複数ファイルの変更）は `feat/`・`fix/`・`refactor/`・`docs/`・`chore/` のブランチで行う．パッケージ1つ追加のような小さな変更は `main` に直接コミット・push してよい．GitHub Actions の auto-update が `nvfetcher` と `flake.lock` を `main` へ直接コミットするのは例外．
- **ブランチ名**: Conventional Commits の型に合わせる．新たな型を追加する場合は `.github/workflows/nix-check.yml` の push 対象と `flake.nix` の pre-commit hooks（convco）を同時に更新する．
- **言語**: ユーザーへの報告は日本語．コードコメントとコミットメッセージは英語．エージェント運用ドキュメント（本ファイル・`docs/`・`.codewhale/`）は日本語．ルートの `README.md` / `README.ja.md` は常に同期して更新し，サブディレクトリの `README.md` は英語のみ．
- **コメント**: コード内コメントは基本的に付けない．後から参照したときに，コードのみでは意図を読めず困る場合のみ1〜2行程度付ける．
- **コミット**: Conventional Commits 準拠．変更の詳細はコミットメッセージと PR の説明に書く．
- **承認**: `main` へのマージ，リモート `main` へのプッシュ，`nixos-rebuild switch` は実行前にユーザー承認が必要．
- **パッケージ実行**: 本環境には `python3` などが未インストールのため，必要なパッケージは `nix run` / `nix shell` を使う．

## 手順

変更・適用の一連の手順は `dev-workflow` スキル，パッケージ・モジュールの追加場所は `editing-guide` スキル，新ホスト追加は `new-host` スキル（詳細は `hosts/README.md`），キャッシュ設定は `nix-cache-optimization` スキル，コマンド集は `useful-commands` スキルを参照．設計リファレンスは `docs/architecture.md`．
