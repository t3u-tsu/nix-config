---
name: new-host
description: 新ホストを追加するときの手順．
---

# 新ホストを追加するとき

エンドツーエンドの詳細は [`docs/operations/adding-a-host.md`](../../../docs/operations/adding-a-host.md) に集約されている．実行前にユーザー承認を必ず得ること．git 操作は `dev-workflow` スキルに従う（ブランチ名: `feat/add-<hostname>`）．

1. `cp -r hosts/_template hosts/<hostname>` し，`HOSTNAME` プレースホルダ・`hardware.nix`（fileSystems/swap）・`services/nebula.nix`（IP/groups）を実機に合わせて編集する．
2. `flake/hosts.nix` に `mkLib.mkSystem { name; system; username; profile; extraModules?; }` を追加する（`profile` は `desktop` / `tower-server` / `gateway` から選択）．
3. パスワード・SOPS: `scripts/set-host-password.sh <hostname>` で初期パスワードを設定し，`.sops.yaml` にホスト鍵を登録して `sops updatekeys` する（詳細は [`docs/operations/secret-management.md`](../../../docs/operations/secret-management.md)）．
4. Nebula: 既存 CA で `nebula-cert sign` → `scripts/nebula-lib.sh` の `FLEET` 配列に追記して import する（詳細は [`docs/architecture/network-topology.md`](../../../docs/architecture/network-topology.md)）．
5. private flake input のブートストラップ: 初回評価時の SSH エイリアス設定は [`docs/operations/adding-a-host.md`](../../../docs/operations/adding-a-host.md) を参照．
6. 検証: `nix flake check` → 事前ビルド `nix build .#nixosConfigurations.<name>.config.system.build.toplevel --no-link`．
7. 適用: デスクトップ機は承認のもと `pkexec` 経由，リモート/SBC 機は `dev-workflow` に従い `--target-host` またはユーザー自身が実行する．
