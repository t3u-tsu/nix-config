---
name: new-host
description: 新ホストを追加するときの手順．
---

# 新ホストを追加するとき

新ホスト追加の手順は [`docs/operations/adding-a-host.md`](../../../docs/operations/adding-a-host.md) を参照．作業開始前にユーザー承認を得る．ブランチ運用は `dev-workflow` スキルに従う（`feat/add-<hostname>`）．

1. `cp -r hosts/_template hosts/<hostname>` を実行し，`HOSTNAME` プレースホルダ，`hardware.nix`（ファイルシステム / スワップ），`services/nebula.nix`（IP / グループ）を実機に合わせて編集する．
2. [`flake/hosts.nix`](../../../flake/hosts.nix) に `mkLib.mkSystem { name; system; username; profile; extraModules?; }` の定義を追加する（`profile` は `desktop` / `tower-server` / `gateway` から選択）．
3. パスワード・SOPS: `scripts/set-host-password.ysh <hostname>` で初期パスワードを設定し，[`.sops.yaml`](../../../.sops.yaml) にホスト公開鍵を登録して `sops updatekeys` を実行する（詳細は [`docs/operations/secret-management.md`](../../../docs/operations/secret-management.md)）．
4. Nebula: 既存 CA で `nebula-cert sign` を実行し，[`scripts/nebula-lib.ysh`](../../../scripts/nebula-lib.ysh) の `FLEET` リストへ追記してインポートする（詳細は [`docs/architecture/network-topology.md`](../../../docs/architecture/network-topology.md)）．
5. private flake input のブートストラップ: 初回評価時の SSH エイリアス設定は [`docs/operations/adding-a-host.md`](../../../docs/operations/adding-a-host.md) を参照．
6. 検証: `nix flake check` → 事前ビルド `nix build .#nixosConfigurations.<name>.config.system.build.toplevel --no-link`．
7. 適用: デスクトップ機はユーザー承認のもと `pkexec` 経由，リモート・SBC 機は `dev-workflow` スキルに従い `--target-host` またはユーザー手動操作で実行する．
