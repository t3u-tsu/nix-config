---
name: new-host
description: 新ホストを追加するときの手順．
---

# 新ホストを追加するとき

新ホスト追加の手順は [`docs/operations/adding-a-host.md`](../../../docs/operations/adding-a-host.md) を参照．作業開始前にユーザー承認を得る．ブランチ運用は `dev-workflow` スキルに従う（`feat/add-<hostname>`）．

1. `cp -r hosts/_template hosts/<hostname>` を実行し，`HOSTNAME` プレースホルダ，`hardware.nix`（ファイルシステム / スワップ），`services/nebula.nix`（IP / グループ）を実機に合わせて編集する．
2. [`flake/hosts.nix`](../../../flake/hosts.nix) に `mkLib.mkSystem { name; system; username; profile; extraModules?; }` の定義を追加する（`profile` は `desktop` / `tower-server` / `gateway` から選択）．
3. `scripts/set-host-password.ysh <hostname>` で初期パスワードを設定し，[`.sops.yaml`](../../../.sops.yaml) にホスト公開鍵を登録して `sops updatekeys` を実行する（詳細は [`docs/operations/secret-management.md`](../../../docs/operations/secret-management.md)）．
4. 既存 CA で `nebula-cert sign` を実行し，[`scripts/nebula-lib.ysh`](../../../scripts/nebula-lib.ysh) の `FLEET` リストへ追記して証明書をインポートする（詳細は [`docs/architecture/network-topology.md`](../../../docs/architecture/network-topology.md)）．
5. 初回評価に必要な private flake input（SSH エイリアス設定等）をブートストラップする（詳細は [`docs/operations/adding-a-host.md`](../../../docs/operations/adding-a-host.md)）．
6. `nix flake check` で全体評価を行い，`nix build .#nixosConfigurations.<name>.config.system.build.toplevel --no-link` で事前ビルドを検証する．
7. デスクトップ機はユーザー承認のもと `pkexec` 経由で適用し，リモート・SBC 機は `dev-workflow` スキルに従い `--target-host` またはユーザー手動操作で適用する．
