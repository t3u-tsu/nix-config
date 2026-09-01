---
name: new-host
description: 新ホストを追加するときの手順．
---

# 新ホストを追加するとき

詳細手順書は `hosts/README.md`（SOPS / Nebula 含むエンドツーエンド）を参照し，ユーザー承認を必ず得ること．テンプレートは `hosts/_template/` をコピーして使う．ブランチ作成からコミット，PR マージまでの git 操作は `dev-workflow` スキルに従う（ブランチ名: `feat/add-<hostname>`）．

1. `cp -r hosts/_template hosts/<hostname>` し，`HOSTNAME` プレースホルダ・`hardware.nix`（fileSystems/swap）・`services/nebula.nix`（IP/groups）を実機に合わせて編集．
2. `flake/hosts.nix` に `mkLib.mkSystem { name; system; username; profile; extraModules?; }` を追加する（`profile` は必ず指定）．
3. SOPS: `.sops.yaml` に age 鍵を登録し `secrets/hosts/<hostname>.yaml` を作成，`sops updatekeys`（詳細は `hosts/README.md` / `secrets/README.md`）．
4. Nebula: 既存 CA で `nebula-cert sign` → `scripts/nebula-lib.sh` の `FLEET` 配列に追記して import（master 鍵が必要）．
5. 検証: `nix flake check` → `nixos-rebuild dry-activate --flake .#<name>`（dry-activate はユーザーが実行）．
6. 適用・PR は通常フロー（ユーザー承認必須）．
