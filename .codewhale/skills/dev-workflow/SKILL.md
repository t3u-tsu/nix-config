---
name: dev-workflow
description: このリポジトリで変更を適用する一連の手順．ブランチ作成から実装，検証，nixos-rebuild switch，コミット，PR 作成・マージまで．変更作業を開始するとき，または PR を出すときに使用する．
---

# 変更・適用手順

1. **ブランチ作成**: 大きな作業（新ホスト追加，モジュール新設，複数ファイルの変更）は `git checkout -b feat/topic-name` でブランチを作成してから実装する．パッケージ1つ追加のような小さな変更は `main` で直接作業してよい．

2. **実装**: 必要な Nix ファイルや設定ファイルを編集する．

3. **検証**
   ```bash
   nix flake check
   ```
   pre-commit の nixfmt / statix / convco を通すこと．statix W:20 を避けるため，同じトップレベルキーはまとめて attrset で定義し，分割して記述しない．

   ```bash
   sudo nixos-rebuild dry-activate --flake .#BrokenPC
   ```

4. **適用（ユーザー承認必須）**: 適用前にユーザーへ確認し，承認を得てから実行する．
   ```bash
   sudo nixos-rebuild switch --flake .#BrokenPC
   ```

5. **コミットとプッシュ**
   ```bash
   git add -A
   git commit -m "feat: topic description"
   git push origin feat/topic-name
   ```
   `main` 直 push の場合はそのまま `git push origin main`．

6. **PR の作成とマージ（GitHub CLI `gh`）**: ユーザー承認のうえ実行する．
   PR 説明文は必ず一時ファイルに書いて `--body-file` で渡すこと．`--body` に特殊記号（`` ` `` など）を含めるとシェルがコマンド置換して本文が壊れるため．
   ```bash
   cat > /tmp/pr-body.md <<'EOF'
   feat: topic description
   ...
   EOF
   gh pr create --title "feat: topic description" --body-file /tmp/pr-body.md
   ```
   マージ前に `gh pr checks` で `nix flake check` の結果を確認するのが推奨．CI が重いため，即マージを優先するなら CI 完了を待たず進めてもよいが，リスクを避けたい場合は `PASS` を待つのを推奨．どちらの運用にするかはその都度ユーザーと合意する．
   ```bash
   gh pr merge --merge --delete-branch
   git checkout main
   git pull origin main
   ```

## 注意

- `main` へのマージ，リモート `main` へのプッシュ，`nixos-rebuild switch` はすべてユーザー承認が必要．
- コミットメッセージは英語，Conventional Commits 準拠．
