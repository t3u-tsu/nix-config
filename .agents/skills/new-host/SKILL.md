---
name: new-host
description: 新ホストを追加するときの手順．
---

# 新ホストを追加するとき

新ホスト追加の手順は [docs/operations/adding-a-host.md](../../../docs/operations/adding-a-host.md) を参照．作業開始前にユーザー承認を得る．ブランチ運用は `dev-workflow` スキルに従う (`feat/add-<hostname>`)．

1. `cp -r hosts/_template hosts/<hostname>` を実行し，`HOSTNAME` プレースホルダ，`hardware.nix` (ファイルシステム / スワップ)，`services/nebula.nix` (追加の `extraInbound` ルール等)を実機に合わせて編集する．Nebula の IP とグループは [lib/nebula-fleet.nix](../../../lib/nebula-fleet.nix) で管理する．
2. [flake/hosts.nix](../../../flake/hosts.nix) の `fleet` attrset に `<hostname> = { system = "..."; profile = "..."; };` を追加する (`profile` は `desktop` / `tower-server` / `gateway` から選択)．SBC 向けの制約 (サンドボックス無効化，swapfile 等) は `profile` ではなく，[hosts/torii-chan/sbc.nix](../../../hosts/torii-chan/sbc.nix) のように [nixos/profiles/sbc](../../../nixos/profiles/sbc) を import するモジュールを `extraModules` で適用する．同一ロールを複数の起動媒体・プラットフォームで運用する場合は `variants` に列挙する (torii-chan を参照)．
3. `just secret set-host-password <hostname>` で初期パスワードを設定し，`hosts/<hostname>/default.nix` の `age.rekey.hostPubkey` を登録して `just secret rekey` を実行する．ホスト公開鍵はインストーラ環境で `sudo ./scripts/install/init-host-key.sh` を実行して取得する (詳細は [docs/operations/secret-management.md](../../../docs/operations/secret-management.md))．
4. 既存 CA で `nebula-cert sign` を実行し，[lib/nebula-fleet.nix](../../../lib/nebula-fleet.nix) の `nodes` へ追記して `just nebula import-secrets` で証明書とノード鍵を取り込む ([scripts/nebula/lib/fleet.ysh](../../../scripts/nebula/lib/fleet.ysh) が `FLEET` として読み込む) (詳細は [docs/architecture/network-topology.md](../../../docs/architecture/network-topology.md))．
5. 初回評価に必要な private flake input (SSH エイリアス設定等)をブートストラップする．`sudo ./scripts/install/setup-deploy-key.sh <hostname>` が deploy key の復号と SSH エイリアス設定を行う (詳細は [docs/operations/adding-a-host.md](../../../docs/operations/adding-a-host.md))．
6. `nix flake check --no-build` で全体評価を行い，`nix build .#nixosConfigurations.<name>.config.system.build.toplevel --no-link` で事前ビルドを検証する．
7. デスクトップ機はユーザー承認のもと `pkexec` 経由で適用し，リモート・SBC 機は `dev-workflow` スキルに従い `--target-host` またはユーザー手動操作で適用する．
