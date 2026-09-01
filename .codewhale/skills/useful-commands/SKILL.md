---
name: useful-commands
description: このリポジトリでよく使うコマンド（デプロイ，sops 編集，Noctalia IPC，gh での PR 運用）を確認したいときに使用する．
---

# 便利なコマンド集

- **デプロイ**: `sudo nixos-rebuild switch --flake .#BrokenPC`
- **torii-chan デプロイ (手動/SBC用)**: `nixos-rebuild switch --flake .#torii-chan-hdd --target-host t3u@10.0.0.1 --sudo --ask-sudo-password --option sandbox false --option filter-syscalls false`
- **秘密情報編集**: `sops secrets/secrets.yaml`
- **IPC 操作 (Noctalia)**: `noctalia ipc call <target> <function>`
- **ビルド完了通知**: `curl -X POST ...` (ビルド成功時に webhook をトリガーする場合)
- **PR作成 (GitHub CLI)**: `gh pr create --title "タイトル" --body-file /tmp/pr-body.md`（本文は `--body-file` で渡し，特殊文字はファイルで安全に扱う）
- **PRマージ (GitHub CLI)**: `gh pr merge --merge --delete-branch`
