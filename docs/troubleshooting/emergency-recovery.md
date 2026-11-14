# 緊急時システム復旧・レスキューガイド

世代ロールバック，`init=/bin/sh` 緊急シェル，インストーラ USB からのレスキューマウント，実機全損時の再構築の手順．

| 障害種別 | エラー兆候 | 影響ホスト | 初動対応 |
| :--- | :--- | :--- | :--- |
| 適用直後のサービス不具合 | `Active: failed (Result: exit-code)` | 全ホスト | `sudo nixos-rebuild switch --rollback` |
| カーネルパニック・起動停止 | `Kernel panic - not syncing: VFS: Unable to mount root fs` | 全ホスト | ブートローダーメニューから健全な世代を選択 |
| シークレット復号不全・activation 失敗 | `You are in emergency mode.` | 全ホスト | `init=/bin/sh` 緊急シェルから前世代の boot 設定を適用 |
| ブートローダー破損・ストレージ設定破壊 | `error: symbol 'grub_calloc' not found.` | 全ホスト | インストーラ USB 起動と `nixos-enter` によるレスキュー |
| 実機全損・ストレージ全損 | `error: no such device: <UUID>.` | 全ホスト | Bitwarden の Master 鍵と Git リポジトリからの再構築 |

---

## 1. 世代ロールバック

### 現象

```text
$ systemctl status <service>
× <service>.service
     Active: failed (Result: exit-code) since ...; 10s ago

# カーネル更新後の起動時
Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0)
```

### 原因

NixOS は過去のシステム構成世代を Nix ストア内に不変に保持する．設定ミスやカーネル不具合は，直前世代への切り替えで解消できる．

### 切り分け・復旧手順

#### 対策 1: 稼働中システムでのロールバック

```bash
sudo nixos-rebuild switch --rollback
nix-env -p /nix/var/nix/profiles/system --list-generations

# 特定の世代番号 (例: 42) へ切り替える場合
sudo /nix/var/nix/profiles/system-42-link/bin/switch-to-configuration switch
```

#### 対策 2: GRUB メニューからの世代選択

対象は `BrokenPC`, `x1c7`, `kagutsuchi-sama`, `shosoin-tan`, `sando-kun`．

1. マシン起動時，マザーボードロゴの表示直後に `Shift` または `Esc` を連打して GRUB メニューを表示する．
2. 「NixOS - All configurations」を選択して `Enter` を押す．
3. 過去の日時と世代番号の一覧から，直前の正常世代を選択して起動する．

#### 対策 3: extlinux メニューからの世代選択

対象は `torii-chan` (Orange Pi Zero 3)．

1. HDMI ディスプレイまたは UART シリアルコンソールを接続して電源を投入する．
2. U-Boot のカウントダウン中に任意のキーを押し，extlinux 世代選択画面を表示する．
3. 正常な世代エントリを選択して起動する．`/boot` は常に SD カード上の `NIXOS_SD` に保持されるため，HDD 側の不具合時でもメニューから起動できる．

#### 対策 4: 旧世代起動後の恒久化

旧世代での起動だけでは，次回の `nixos-rebuild switch` で不具合のある設定が再びビルド・適用される．

1. 不具合の原因となったコミットを特定し，`git revert` または設定を修正する．
2. 修正した設定で新たな健全世代を作成する．

   ```bash
   sudo nixos-rebuild switch --flake .#<hostname>
   ```

---

## 2. `init=/bin/sh` 緊急シェルによる復旧

### 現象

```text
You are in emergency mode. After logging in, type "journalctl -xb" to view system logs...
Give root password for maintenance (or press Control-D to continue):
```

[nixos/base/user.nix](../../nixos/base/user.nix) で root パスワードは未設定 (アカウントロック) のため，このプロンプトからはログインできない．

### 原因

activation スクリプト (シークレット復号，ユーザー・グループ作成，ファイル配置等) が非ゼロ終了すると，systemd のブートプロセスが中断して emergency mode へ移行する．パスワードによるコンソールログインが行えないため，カーネルパラメータで直接シェルを起動する．

### 切り分け・復旧手順

#### 対策 1: 失敗ユニットの特定

1. マシンを再起動し，GRUB メニューで対象世代を選択した状態で `e` キーを押してエントリ編集画面に入る．
2. `linux /nix/store/.../bzImage` で始まる行の末尾に `init=/bin/sh` を追記し，`Ctrl+X` または `F10` で起動する．
3. 失敗ユニットとエラーログを確認する．

   ```bash
   systemctl --failed
   journalctl -xb -p 3
   ```

#### 対策 2: 前世代の boot 設定への切り替え

1. ルートファイルシステムを書き込み可能で再マウントする．

   ```bash
   mount -o remount,rw /
   ```

2. 健全な世代リンクを確認する．

   ```bash
   ls -l /nix/var/nix/profiles/system-*-link
   ```

3. 前世代の boot 設定を適用する．`init=/bin/sh` 環境には systemd がないため `boot` サブコマンドを指定する．

   ```bash
   /nix/var/nix/profiles/system-<世代番号>-link/bin/switch-to-configuration boot
   reboot -f
   ```

#### 対策 3: `systemd.unit=rescue.target` による起動

`init=/bin/sh` 環境で必要なツールが不足する場合は，同じ編集画面で `init=/bin/sh` の代わりに `systemd.unit=rescue.target` を追記して起動する．systemd を起動したまま root シェルを取得できる．

---

## 3. インストーラ USB によるレスキューマウントと nixos-enter

### 現象

```text
error: symbol `grub_calloc' not found.
Entering rescue mode...
grub rescue> ls
(hd0) (hd0,gpt1) (hd0,gpt2)
```

### 原因

ブートローダー自体の破損，ストレージ設定の破壊，シークレット復号失敗により，ブートメニューからの復旧が不可能な状態．インストーラ環境から対象ルートをマウントし，`nixos-enter` で対象システムのコンテキストに入って修復する．

### 切り分け・復旧手順

#### 対策 1: インストーラ USB の起動

1. 公式 NixOS 最小インストーラ USB (またはカスタムインストーラ ISO) を用意し，対象マシンを USB ブートする．
2. インストーラ環境の root プロンプトに入る．

#### 対策 2: ストレージ構成別のマウント

```mermaid
flowchart TD
    USB["インストーラ USB で起動"] --> Identify["lsblk / blkid でパーティション確認"]
    Identify --> Type{ホストのストレージ種別}

    Type -->|"UEFI + GPT<br>(BrokenPC, x1c7, kagutsuchi)"| MountA["mount root /mnt<br>mount efi /mnt/boot"]
    Type -->|"レガシー BIOS 構成<br>(shosoin-tan: SSD + ZFS,<br>sando-kun: HDD)"| MountB["mount root /mnt<br>mount boot /mnt/boot<br>(shosoin-tan のみ: zpool import)"]
    Type -->|"SBC (SD + HDD)<br>(torii-chan)"| MountC["mount NIXOS_HDD /mnt<br>mount NIXOS_SD /mnt/boot"]

    MountA --> Enter["nixos-enter --root /mnt"]
    MountB --> Enter
    MountC --> Enter
```

| 構成 | 対象ホスト | マウント操作 |
| :--- | :--- | :--- |
| UEFI + GPT | `BrokenPC`, `x1c7`, `kagutsuchi-sama` | ルートを `/mnt`，EFI パーティションを `/mnt/boot` へマウント |
| レガシー BIOS | `shosoin-tan` (SSD + ZFS), `sando-kun` (HDD) | ルートを `/mnt`，boot を `/mnt/boot` へマウント．`shosoin-tan` は `zpool import -f -R /mnt tank-1tb` を追加 |
| SBC | `torii-chan-hdd` | `NIXOS_HDD` を `/mnt`，`NIXOS_SD` を `/mnt/boot` へマウント |

```bash
# UEFI + GPT (BrokenPC, x1c7, kagutsuchi-sama)
mount /dev/disk/by-id/<root-partition> /mnt
mount /dev/disk/by-id/<efi-partition> /mnt/boot

# レガシー BIOS (shosoin-tan: SSD + ZFS)
mount /dev/disk/by-id/ata-CT480BX500SSD1_1946E3D7A95A-part3 /mnt
mount /dev/disk/by-id/ata-CT480BX500SSD1_1946E3D7A95A-part2 /mnt/boot
zpool import -f -R /mnt tank-1tb

# レガシー BIOS (sando-kun: HDD のみ，ZFS 非搭載)
mount /dev/disk/by-id/ata-ST9250320AS_5SW1VK4F-part3 /mnt
mount /dev/disk/by-id/ata-ST9250320AS_5SW1VK4F-part2 /mnt/boot

# SBC (torii-chan-hdd)
mount /dev/disk/by-label/NIXOS_HDD /mnt
mount /dev/disk/by-label/NIXOS_SD /mnt/boot
```

#### 対策 3: `nixos-enter` による復旧作業

```bash
nixos-enter --root /mnt
```

1. SSH ホスト秘密鍵の存在とパーミッションを確認・修復し，公開鍵を `hosts/<hostname>/default.nix` の `age.rekey.hostPubkey` と突合する．

   ```bash
   ls -la /etc/ssh/ssh_host_ed25519_key
   chmod 600 /etc/ssh/ssh_host_ed25519_key
   cat /etc/ssh/ssh_host_ed25519_key.pub
   ```

2. ブートセクタの破損や EFI 変数の欠落がある場合は，ブートローダーを強制再インストールする．

   ```bash
   NIXOS_INSTALL_BOOTLOADER=1 /nix/var/nix/profiles/system/bin/switch-to-configuration boot
   ```

3. 特定の健全世代をブート既定に設定する．

   ```bash
   /nix/var/nix/profiles/system-35-link/bin/switch-to-configuration boot
   ```

4. ネットワークが利用できる場合は設定を修正してリビルドする．

   ```bash
   cd /home/t3u/nix-config
   nixos-rebuild boot --flake .#<hostname>
   ```

#### 対策 4: レスキュー環境からの脱出

```bash
exit
umount -R /mnt

# shosoin-tan で ZFS プールをインポートした場合のみ
zpool export tank-1tb

reboot
```

> [!CAUTION]
> `shosoin-tan` で ZFS プールをインポートした場合は，再起動前に必ず `zpool export tank-1tb` を実行する．全ホスト共通のベース設定で `boot.zfs.forceImportRoot = false` が有効なため，エクスポートを怠ると次回起動時にプールをインポートできず emergency mode に陥る．

---

## 4. 実機全損・ストレージ全損時の再構築

### 現象

```text
error: no such device: <UUID>.
Entering rescue mode...
grub rescue>
```

ディスクが `lsblk` に列挙されない，または SMART エラーで I/O が返らない場合はストレージの物理故障を疑う．

### 原因

ハードウェアの物理故障，ストレージ換装，管理端末を含む複数機の被災により，既存の世代とシークレット復号鍵が失われる．Bitwarden Vault と GitHub リポジトリから再構築する．

| 保管先 | アイテム / パス | 内容・用途 |
| :--- | :--- | :--- |
| 公開 Git リポジトリ | `https://github.com/t3u-tsu/nix-config` | NixOS 構成宣言および再暗号化シークレット |
| Bitwarden Vault | `nix-config/agenix-master-key` | agenix-rekey Master age 秘密鍵 (`AGE-SECRET-KEY-1...`) |
| Bitwarden Vault | `nix-config/ssh/<hostname>` | 運用者 SSH 鍵 (`id_ed25519`) |
| Bitwarden Vault | `nix-config/nebula-ca/ca.key` | Nebula ルート CA 秘密鍵バックアップ |

### 切り分け・復旧手順

#### 対策 1: 健全な管理端末からの再構築

管理端末 (`BrokenPC` または `x1c7`) が稼働している場合，[新規ホスト追加手順](../operations/adding-a-host.md) の Step 1〜Step 5 に従って再構築する．ディスクの初期化，ホスト鍵の生成，`age.rekey.hostPubkey` の更新と `just secret rekey`，deploy key の設定，`nixos-install` は同手順に含まれる．新しいホスト鍵による再暗号化と旧鍵の失効は [ホスト再インストール時のホスト鍵ローテーション](../operations/secret-management.md#step-10-ホスト再インストール時のホスト鍵ローテーション) を参照する．

データサーバー (`shosoin-tan`) は再起動後に [バックアップ運用 & ディザスタリカバリ (DR)](../operations/backup-and-restore.md) に従って Restic からデータを復元する．

#### 対策 2: Live USB 単独でのブートストラップ

管理端末が手元になく，インストーラ USB と Bitwarden Vault のみから復旧する場合．ホスト鍵の生成以降は [新規ホスト追加手順](../operations/adding-a-host.md) と共通のため，差分のみ示す．

1. Bitwarden から Master 鍵と運用者 SSH 鍵を取得する．agenix-rekey が参照する tmpfs パスへ Master 鍵を展開する．

   ```bash
   sudo mkdir -p -m 0700 /run/agenix-master
   sudo mount -t tmpfs -o noswap,nodev,noexec,nosuid,size=1M tmpfs /run/agenix-master
   cat <<'EOF' | sudo tee /run/agenix-master/master-key.txt >/dev/null
   AGE-SECRET-KEY-1...
   EOF
   sudo chmod 0400 /run/agenix-master/master-key.txt
   ```

2. 運用者 SSH 鍵を `/root/.ssh/id_ed25519` に配置し，private input 用の鍵として複製する．

   ```bash
   sudo install -d -m 700 /root/.ssh
   cat <<'EOF' | sudo tee /root/.ssh/id_ed25519 >/dev/null
   -----BEGIN OPENSSH PRIVATE KEY-----
   ...
   -----END OPENSSH PRIVATE KEY-----
   EOF
   sudo chmod 600 /root/.ssh/id_ed25519
   sudo cp /root/.ssh/id_ed25519 /root/.ssh/nix-config-private_deploy_key
   ```

3. ホスト鍵の生成は [Step 1](../operations/adding-a-host.md#step-1-ディスクの準備と-ssh-ホスト鍵の生成)，`age.rekey.hostPubkey` の更新と再暗号化は [Step 3](../operations/adding-a-host.md#step-3-暗号化シークレットの登録と再暗号化)，deploy key の設定は [deploy key の設定](../operations/adding-a-host.md#deploy-key-の設定)，インストールは [Step 5](../operations/adding-a-host.md#step-5-インストールと初回起動) に従う．Live USB 環境で再暗号化する場合は `nix develop --command just secret rekey` を実行する．

---

## 関連ドキュメント
- [目次](../README.md) — 全ドキュメントの索引
- [新規ホスト追加手順](../operations/adding-a-host.md) — ディスク準備からインストールまでの標準手順
- [シークレット & 鍵ライフサイクル管理](../operations/secret-management.md) — Master 鍵の保管，再暗号化，ホスト鍵ローテーション
- [シークレット・認証トラブルシューティング](secrets-and-auth.md) — シークレット復号エラー，private input 認証失敗の復旧
- [ビルド・デプロイ障害トラブルシューティング](build-and-deploy.md) — ビルド・評価時の OOM，lock 不整合，権限昇格エラーの復旧
- [バックアップ運用 & ディザスタリカバリ (DR)](../operations/backup-and-restore.md) — Restic バックアップ運用，障害時リストア手順
- [ZFS 保守・リビルドガイド](../hardware/storage-zfs.md) — レガシー BIOS ブート，ZFS Mirror 保守・ディスク交換手順
- [Orange Pi Zero 3 ハードウェアガイド](../hardware/orange-pi-zero3.md) — Allwinner H618 SBC, U-Boot，低スペック制約
