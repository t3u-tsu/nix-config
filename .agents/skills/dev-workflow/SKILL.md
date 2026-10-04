---
name: dev-workflow
description: このリポジトリで設定変更を適用するときの手順．変更作業を開始するとき使用する．
---

# 変更・適用手順

1. **ブランチ作成**: ブランチを切るかは AGENTS.md の基本ルールに従う．切る場合は `git checkout -b feat/topic-name`．

2. **実装**: Nix ファイルや設定ファイルを編集する．秘密情報は `sops` で編集する（`secrets/README.md`）．

3. **検証**
   必要に応じて `nix flake check` 及び `nixos-rebuild build` を行う．それぞれ実行に時間を要するため，明確に不要だと判断できる場合はスキップしたり，実行中に先に報告したりしても良い．また `nixos-rebuild build` はビルドキャッシュを生成するため，ユーザーが `nixos-rebuild switch` を実行する時間を短縮できる．
   ```bash
   nix flake check
   ```
   `nix flake check` は pre-commit hooks も実行する．また flake は git 追跡下のものを見るので実行の際は `git add` をする必要がある．
   個別に nixfmt を実行する場合は**ファイル単位**で指定する:
   ```bash
   nixfmt --check <file>
   nixfmt <file>
   ```
   - statix: 同じトップレベルキーはまとめて attrset で定義し，分割して記述しない．引数が空の場合は `{ ... }:` ではなく `_:` を使用する．
   - shellcheck は `scripts/*.sh` が対象で `-x` 付き（`nebula-lib.sh` の source を追う）．
   - ja-punctuation は `.md` が対象．**日本語文書の句読点は `，．` を使う**（他の句読点はフックが自動置換する）．
   - end-of-file-fixer は全テキストファイルの末尾改行を揃える．`_sources/generated.{json,nix}` は nvfetcher の生成物なので除外している．
   - trim-trailing-whitespace は行末の空白を落とす．Markdown の行末スペース2つは改行の意味を持つため，改行したい場合は `<br>` を使う．

   設定がビルドできることを確認する場合:
   ```bash
   nixos-rebuild build --flake .#<hostname>
   ```

4. **適用**:
   デスクトップ環境（Polkit エージェントが動作している x1c7 など）では，事前にユーザーの承認を得たうえで，エージェントが `pkexec` 経由で実行できる:
   ```bash
   pkexec --keep-cwd nixos-rebuild dry-activate --flake .#<hostname>
   pkexec --keep-cwd nixos-rebuild switch --flake .#<hostname>
   ```
   実行するとデスクトップ上に Polkit の GUI 認証ダイアログ（実行コマンドが表示される）がポップアップし，ユーザーが指紋認証やパスワード入力で承認・認証を行う．
   特権昇格の保留時間を最小化するため，**必ず事前にビルド（`nixos-rebuild build --flake .#<hostname>` または `nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel --no-link`）を完了させてから実行する**．これにより，ユーザーの認証直後に瞬時に切り替えが完了する．

   ヘッドレス環境（torii-chan など）・SSH 経由・Polkit が利用できない場合のフォールバックでは，従来どおりユーザー自身が実行する:
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

6. **PR（`gh`）**: ユーザー承認のうえ実行する． git の履歴を残すため，基本的にマージは PR を作成しリモートブランチ上で行う．説明文は一時ファイルに書いて `--body-file` で渡す．`--body` にバッククォート等を含めるとシェルがコマンド置換して本文が壊れるため使わない．
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
