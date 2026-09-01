---
name: dev-workflow
description: このリポジトリで設定変更を適用するときの手順．変更作業を開始するとき使用する．
---

# 変更・適用手順

1. **ブランチ作成**: どの作業でブランチを切るかは AGENTS.md の基本ルールに従う．ブランチを切る場合は `git checkout -b feat/topic-name` を実行する．

2. **実装**: 必要な Nix ファイルや設定ファイルを編集する．秘密情報を変更する場合は `sops` で編集する（`sops secrets/secrets.yaml`，詳細は `secrets/README.md`）．

3. **検証**
   ```bash
   nix flake check
   ```
   pre-commit の nixfmt / statix / convco を通すこと．statix W:20 を避けるため，同じトップレベルキーはまとめて attrset で定義し，分割して記述しない．

   設定がビルドできることを確認する場合:
   ```bash
   nix build .#nixosConfigurations.BrokenPC.config.system.build.toplevel
   ```

4. **適用**: `sudo` を要する操作はエージェントが実行できないため，ユーザーが実行する．
   ```bash
   sudo nixos-rebuild dry-activate --flake .#BrokenPC
   sudo nixos-rebuild switch --flake .#BrokenPC
   ```
   torii-chan へのリモートデプロイ（手動/SBC用，ユーザー実行）:
   ```bash
   nixos-rebuild switch --flake .#torii-chan-hdd --target-host t3u@10.0.0.1 --sudo --ask-sudo-password --option sandbox false --option filter-syscalls false
   ```

5. **コミットとプッシュ**（コミットメッセージは英語，Conventional Commits 準拠）
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
   マージ前に `gh pr checks` で `nix flake check` の結果を確認することを推奨．即マージを優先するなら CI 完了を待たず進めてもよいが，リスクを避けたい場合は `PASS` を待つのを推奨．どちらの運用にするかはその都度ユーザーと合意する．
   ```bash
   gh pr merge --merge --delete-branch
   git checkout main
   git pull origin main
   ```
