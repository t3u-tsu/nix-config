---
name: new-host
description: 新ホストを追加するときの手順．
---

# 新ホストを追加するとき

エンドツーエンドの詳細は `hosts/README.md`（SOPS / Nebula 含む）にある．実行前にユーザー承認を必ず得ること．git 操作は `dev-workflow` スキルに従う（ブランチ名: `feat/add-<hostname>`）．

1. `cp -r hosts/_template hosts/<hostname>` し，`HOSTNAME` プレースホルダ・`hardware.nix`（fileSystems/swap）・`services/nebula.nix`（IP/groups）を実機に合わせて編集する．
2. `flake/hosts.nix` に `mkLib.mkSystem { name; system; username; profile; extraModules?; }` を追加する（`profile` は必須）．
3. SOPS: `.sops.yaml`（要承認）に `&<hostname> age1...` と creation rule を追加し，`secrets/hosts/<hostname>.yaml` を作成して `sops updatekeys` する．host 専用の age identity は operator 側に無いため，master 鍵を `SOPS_AGE_KEY_FILE` で渡す（手順は `secrets/README.md`）．
4. Nebula: 既存 CA で `nebula-cert sign` → `scripts/nebula-lib.sh` の `FLEET` 配列に追記して import する（master 鍵が必要）．
5. 検証: `nix flake check` → `nixos-rebuild dry-activate --flake .#<name>`（dry-activate はユーザーが実行）．
6. 適用・PR は通常フロー（ユーザー承認必須）．
