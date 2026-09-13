---
name: dev-workflow
description: このリポジトリで設定変更を適用するときの手順．変更作業を開始するとき使用する．
---

# 変更・適用手順

1. **ブランチ作成**: ブランチを切るかは AGENTS.md の基本ルールに従う．切る場合は `git checkout -b feat/topic-name`．

2. **実装**: Nix ファイルや設定ファイルを編集する．秘密情報は `sops` で編集する（`secrets/README.md`）．

3. **検証**
   ```bash
   nix flake check
   ```
   `nix flake check` は pre-commit hooks（nixfmt / statix / convco / shellcheck / ja-punctuation）も実行する．個別に nixfmt を実行する場合は**ファイル単位**で指定する:
   ```bash
   nixfmt --check <file>
   nixfmt <file>
   ```
   - statix W:20 を避けるため，同じトップレベルキーはまとめて attrset で定義し，分割して記述しない．
   - shellcheck は `scripts/*.sh` が対象で `-x` 付き（`nebula-lib.sh` の source を追う）．
   - ja-punctuation は `.md` が対象．**日本語文書の句読点は `，．` を使う**（他の句読点はフックが自動置換する）．

   設定がビルドできることを確認する場合:
   ```bash
   nixos-rebuild build --flake .#<hostname>
   ```

4. **適用**: `sudo` を要する操作はエージェントが実行できないため，ユーザーが実行する．
   ```bash
   sudo nixos-rebuild dry-activate --flake .#<hostname>
   sudo nixos-rebuild switch --flake .#<hostname>
   ```
   torii-chan へのリモートデプロイ（手動/SBC 用，ユーザー実行）:
   ```bash
   nixos-rebuild switch --flake .#torii-chan-hdd --target-host t3u@10.0.0.1 --sudo --ask-sudo-password --option sandbox false --option filter-syscalls false
   ```

5. **コミットとプッシュ**（メッセージは英語，Conventional Commits 準拠）
   ```bash
   git add -A
   git commit -m "feat: topic description"
   git push origin feat/topic-name
   ```
   `main` 直 push は `git push origin main`．

6. **PR（`gh`）**: ユーザー承認のうえ実行する．説明文は一時ファイルに書いて `--body-file` で渡す．`--body` にバッククォート等を含めるとシェルがコマンド置換して本文が壊れるため使わない．
   ```bash
   cat > /tmp/pr-body.md <<'EOF'
   feat: topic description
   ...
   EOF
   gh pr create --title "feat: topic description" --body-file /tmp/pr-body.md
   gh pr checks          # nix flake check の結果を確認（待つかは都度ユーザーと合意）
   gh pr merge --merge --delete-branch
   git checkout main
   git pull origin main
   ```
