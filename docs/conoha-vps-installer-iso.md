# ConoHa VPS（512MB）向けカスタム NixOS インストーラ ISO - 設計・ビルド・インストール手順書

対象: ConoHa VPS `g2l-t-c1m512`（1 vCPU / 512MB RAM / 30GB ブートボリューム、x86_64）
設定一式: `hosts/torii-chan/vps-installer.nix` / 調査メモ: `docs/research-notes.md`

## 1. 背景と方針

- ConoHa は NixOS を標準 OS として提供しないため、`terraform/scripts/nixos-iso.sh` で
  ISO を CD-ROM（rescue）として注入し、ブート後にディスクを上書きインストールする。
- 512MB RAM では **nixos-anywhere は不可**（公式要件 1.5GB RAM、kexec + ターゲット上での
  nix-daemon 実行を前提とするため）。
- 標準の NixOS minimal ISO は「sshd は有効だが（mkDefault true）、ログインにはコンソールで
  パスワードを設定するか authorized_keys を手で追加する必要があり、かつ NetworkManager /
  DHCP 前提」。ConoHa は **DHCP を提供しない**ため、VNC コンソールでの手作業（遅い・
  非対話化が難しい）に依存していた。
- **対策**: カスタム ISO に以下を組み込んで、SSH だけでインストールを完結させる。

  1. sshd 有効化 + root の `authorizedKeys`（公開鍵のみ・パスワード認証無効）
  2. 静的 IP 設定（ConoHa の割当 IP。`conoha.installer.wan` オプションで指定）
  3. 512MB 向け低メモリ設定（zram / swappiness / シリアルコンソール）
  4. `nixos-install` 自動化スクリプト `install-nixos` の同梱

## 2. 生成方式の選択（nixos-generators は非推奨）

`nixos-generators` は **NixOS 25.05 以降 nixpkgs に統合され非推奨**（リポジトリは
nixos-26.05 を使用）。そのため nixpkgs 標準の image framework を使う:

- `system.build.images.iso-installer` … インストーラ ISO（`installation-cd-base.nix` を
  自動付加。nixos-generators の `install-iso` フォーマット相当）
- `system.build.images.iso` … 素のライブ ISO（インストーラ無し。`iso-image.nix` のみ）

ルートフレークに統合済み（`flake/hosts.nix` の `torii-chan-vps-installer`）。
`nix build .#torii-chan-vps-iso -o result-iso` でビルドする（または
`nix build .#nixosConfigurations.torii-chan-vps-installer.config.system.build.images.iso-installer`）。

## 3. 静的 IP の設定

ConoHa VPS は DHCP を提供しない。IP は `terraform apply` 後に確定する:

```bash
terraform output -json torii_chan_addresses
```

`hosts/torii-chan/vps-installer.nix` の `conoha.installer.wan` オプションで `ipv4` / `gateway` を実 IP に指定してからビルドする。
未確定のまま（null）ビルドするとビルド時に警告が出る。その場合は ISO 起動後に
VNC コンソールから手動設定する:

```bash
IPV4=203.0.113.10 PREFIX=24 GATEWAY=203.0.113.1 install-nixos network
```

インターフェース名は virtio NIC を `eth0` に固定する設定（`networking.usePredictableInterfaceNames
= false`）を入れてある。起動後に `ip link` で確認し、違う名前なら
`conoha.installer.interface` を変更する。

## 4. ビルド

```bash
cd /home/t3u/nix-config   # リポジトリ直下

# conoha.installer.wan に IP を設定してから（未設定なら起動後に install-nixos.sh network）
nix build .#torii-chan-vps-iso -o result-iso

# 生成物
ls -lh result-iso/iso/
# nixos-26.05.<...>-x86_64-linux.iso（約 700MB〜1GB。同梱するソフトウェアにより変動）
```

### 一時パスワード（ライブ環境用）

ISO には本番（SOPS 管理）のパスワードハッシュを焼き込まない。ライブ環境の
`root` / `t3u` のパスワードは次の 2 択:

- **パスワードなし（SSH 鍵のみ）**: 上記の通常ビルドで十分（推奨）。
- **一時パスワードを自動発行**: `./hosts/torii-chan/build-vps-iso.sh`
  がランダム生成 → `--impure` ビルドで ISO に焼き込み、
  `result-iso-temp-password.txt`（0600）に保存して表示する。VNC コンソールで
  ログインする場合のみ必要。

インストール後の本番システムは `nixos-rebuild switch --flake .#torii-chan-vps`
で SOPS 管理のパスワードに切り替わる。

## 5. 注入と SSH 接続

```bash
# 1. ISO を注入して rescue ブート
./terraform/scripts/nixos-iso.sh install <instance_id> ./result-iso/iso/nixos-*.iso

# 2. SSH 接続（root は公開鍵のみ。初回はホスト鍵が毎回変わるため StrictHostKeyChecking を無効化しても良い）
ssh -o StrictHostKeyChecking=no root@<public_ip>

# 3. 状態確認
install-nixos status
```

## 6. nixos-install の実行（512MB での注意）

```bash
# ディスクを消去するため INSTALL_YES=1 が必須
INSTALL_YES=1 install-nixos install
```

スクリプトの内容（`hosts/torii-chan/install-nixos.sh`）:

1. `parted` で MBR パーティション作成（BIOS ブート。ConoHa ボリュームは /dev/vda）
2. `mkfs.ext4` → `/mnt` にマウント
3. **swap ファイル（1G）を作成して `swapon`** ← ライブ環境の RAM 補助を兼ねる
4. `nixos-generate-config` → 最小 `configuration.nix` を生成（静的 IP・SSH 鍵・swap 設定入り）
5. `nixos-install --no-root-passwd`（root は鍵ログインのみ）

### 512MB 制約のポイント

- ライブ環境の `/nix/store` は **tmpfs オーバーレイ（RAM 上）**。キャッシュから
  不足パスをダウンロードして展開すると RAM を消費するため、**先に swap を張る**こと
  （上記 3。`install-nixos.sh install` が自動で行う）。
- 公式の installation-device は低メモリ向けに `vm.overcommit_memory=1` と
  `GC_INITIAL_HEAP_SIZE=1M` を設定済み。本設定はさらに zram + swappiness=100 を追加する。
- **完全オフラインで確実に**したい場合は、ターゲットシステムのクロージャを ISO の
  ストアに含めてからビルドする（ビルドマシンで nix ビルド済みのクロージャを再利用）:

  ```nix
  # hosts/torii-chan/vps-installer.nix に追加する例（ターゲット設定ができた後）
  isoImage.storeContents = [
    # 例: (nixpkgs.lib.nixosSystem { ... }).config.system.build.toplevel
  ];
  ```

  こうすると nixos-install は ISO 内のストアからクロージャをコピーするだけで
  ネットワークダウンロードが不要になり、512MB でも余裕を持ってインストールできる。
- キャッシュ経由（cache.nixos.org）で不足分を取得する運用も可能だが、OOM しやすいため
  swap 必須。`nix.settings.max-jobs = 1` 相当の設定（ライブ環境では不要な場合が多い）。

## 7. インストール後の手順

```bash
# ターゲットの SSH を確認してから（同じ静的 IP）
swapoff /mnt/swapfile && umount /mnt   # ※ nixos-install が /mnt をそのままにして終わる場合のみ

# ISO を排出して通常ブート（ローカルマシンで）
./terraform/scripts/nixos-iso.sh eject <instance_id>

# 以降は通常の運用（nixos-rebuild / deploy-rs 等）。割当 IP は vps.nix 側の
# wanIp / wanGateway にも反映する（別タスク）
```

## 8. トラブルシューティング

| 症状 | 原因と対策 |
| :--- | :--- |
| VNC コンソールに文字が出ない | `nomodeset` / `console=tty0` を確認。起動メニューで `e` を押してカーネルパラメータを直接編集する手もある |
| SSH が繋がらない | 静的 IP / ゲートウェイの誤り。`install-nixos status` で確認し、`IPV4=... install-nixos network` で再設定。ゲートウェイが同一サブネットに無い場合は onlink 構成（スクリプトは自動試行） |
| インターフェース名が違う | `ip link` で確認し、`conoha.installer.interface`（またはインストール時の `IFACE`）を変更 |
| nixos-install が OOM で落ちる | swap が有効か確認（`free -h` / `swapon --show`）。`install-nixos.sh install` は自動で swap を作るが、手動実行時は先に `fallocate -l 1G /mnt/swapfile && chmod 600 /mnt/swapfile && mkswap /mnt/swapfile && swapon /mnt/swapfile` |
| ISO からブートしない | `nixos-iso.sh status <instance_id>` で状態確認。rescue イメージは IDE CD-ROM（hw_rescue_bus=ide）で注入される。BIOS ブートのため `isoImage.makeBiosBootable` が有効か確認（x86 ではデフォルト有効） |
| `system.stateVersion` の警告 | ターゲット設定の stateVersion はリポジトリの nixos 設定に合わせて調整する |
