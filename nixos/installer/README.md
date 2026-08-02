# nixos/installer - ConoHa VPS (512MB) 用カスタム NixOS インストーラ ISO

ConoHa VPS（`g2l-t-c1m512` = 1 vCPU / 512MB RAM / 30GB ボリューム）に NixOS を
インストールするための**SSH から操作できるインストーラ ISO** の設定一式。

512MB プランでは nixos-anywhere が使えない（公式要件 1.5GB RAM）ため、
`terraform/scripts/nixos-iso.sh` による rescue ISO 注入方式を使う。
本ディレクトリの設定でビルドした ISO は、SSH 有効 + 静的 IP + authorizedKeys
（公開鍵）を組み込んでおり、VNC コンソールを介さずに SSH から
`nixos-install` を実行できる。

## 構成

| ファイル | 役割 |
| :--- | :--- |
| `default.nix` | エントリポイント（NixOS モジュール）。`conoha.installer.*` オプション定義と子モジュールの import |
| `network.nix` | 静的 IP 設定（ConoHa は DHCP 無効）。NetworkManager 無効化・ファイアウォール |
| `ssh.nix` | sshd 有効化 + root の authorizedKeys（公開鍵のみ・パスワード認証無効） |
| `memory.nix` | 512MB 向け: zram、vm.swappiness、シリアルコンソール用カーネルパラメータ |
| `installer-tools.nix` | 補助スクリプト `install-nixos` と curl を ISO に同梱 |
| `install-nixos.sh` | ネットワーク手動設定 / ディスク分割 / swap / nixos-install の自動化スクリプト |
| `wan-ip.nix` | 静的 IP の差し込み口（IP は terraform apply 後に確定するためここで設定） |
| `flake.nix` | スタンドアロンビルド用サブ flake（ルート flake.nix は変更しない） |

## ビルド

```bash
# （任意）静的 IP を焼き込む場合: nixos/installer/wan-ip.nix の ipv4 / gateway を設定
#   IP は terraform apply 後: terraform output -json torii_chan_addresses
nix build path:./nixos/installer#default -o result-iso
ls result-iso/iso/   # nixos-<version>-x86_64-linux.iso
```

`nixos-generators` は NixOS 25.05 以降 nixpkgs に統合され非推奨のため、
nixpkgs 標準の image framework（`system.build.images.iso-installer`）を使用する。

## ルート flake.nix への統合（別タスク）

ルート flake.nix に統合する場合の例（本タスクでは実施しない）:

```nix
# flake.nix（統合時）: nixosConfigurations に追加するか、packages を直接公開する
packages.x86_64-linux.torii-chan-iso =
  self.nixosConfigurations.<iso-config>.config.system.build.images.iso-installer;
```

または `nixos-rebuild build-image` を使用:

```bash
nixos-rebuild build-image --image-variant iso-installer -I nixos-config=./nixos/installer/default.nix
```

## 注入とインストール

```bash
# ISO 注入（ConoHa rescue モードでブート）
./terraform/scripts/nixos-iso.sh install <instance_id> ./result-iso/iso/nixos-*.iso

# SSH 接続（静的 IP を焼き込んだ場合。鍵は authorizedKeys に登録済み）
ssh root@<public_ip>

# インストール実行（ディスクを消去するため INSTALL_YES=1 が必要）
INSTALL_YES=1 install-nixos install

# 完了後、ISO を排出して通常ブート
./terraform/scripts/nixos-iso.sh eject <instance_id>
```

詳細は [docs/conoha-vps-installer-iso.md](../../docs/conoha-vps-installer-iso.md) を参照。
