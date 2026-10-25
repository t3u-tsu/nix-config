# 緊急時システム復旧・レスキューガイド

システムの世代ロールバック，ブートローダーメニューでの旧世代選択，およびインストーラ USB からレスキューマウントして `nixos-enter` で復旧する手順．

| 障害シナリオ | システム状態 | 推奨復旧手段 | 所要時間・難易度 |
| :--- | :--- | :--- | :--- |
| 適用直後のサービス不具合 | OS 稼働中 (SSH / TTY ログイン可) | `sudo nixos-rebuild switch --rollback` | 数秒 (最小) |
| カーネルパニック / 起動停止 | ブートローダー動作可 | GRUB / extlinux メニューから健全な過去世代を選択起動 | 1〜2 分 (低) |
| 復号不全による emergency mode | ブートローダー動作可，ログイン不可 | GRUB 編集で `init=/bin/sh` 緊急シェルより前世代 boot 設定 | 3〜5 分 (中) |
| ブートセクタ破壊 / 設定崩壊 | OS 起動不可 | NixOS インストーラ USB 起動 + `nixos-enter` レスキュー | 10〜15 分 (高) |
| 実機全損 / ストレージ全損 | OS 起動不可，ハード全損 | Bitwarden Master 鍵 + Git リポジトリからのクリーン再構築 | 20〜30 分 (高) |

---

## 1. 世代ロールバック手順

NixOS は過去のシステム構成世代を Nix ストア内に不変に保持しているため，設定ミスやカーネル不具合の発生時にも即座に正常状態へ復元できる．

### パターン A: 稼働中システムでのロールバック
設定変更の適用直後にサービスの起動失敗や不具合に気づいた場合:

```bash
# 1. 直前の世代へ瞬時に切り替え
sudo nixos-rebuild switch --rollback

# 2. 世代一覧の確認
nix-env -p /nix/var/nix/profiles/system --list-generations

# 3. 特定の世代番号 (例: generation 42) へ切り替える場合
sudo /nix/var/nix/profiles/system-42-link/bin/switch-to-configuration switch
```

### パターン B: 起動時ブートローダーメニューでの世代選択
設定ミスやカーネル更新により OS が起動不能 (カーネルパニック，systemd クラッシュ) になった場合，再起動時のブートローダーメニューから直接過去の世代を選択して起動する．

#### 1. GRUB メニュー (`BrokenPC`, `x1c7`, `kagutsuchi-sama`, `shosoin-tan`, `sando-kun`)
1. マシン起動時，マザーボードロゴが表示された直後に `Shift` キーまたは `Esc` キーを連打して GRUB メニューを表示させる．
2. メニューから「NixOS - All configurations」を選択して `Enter` を押す．
3. 過去の日時および世代番号の一覧が表示されるため，直前の正常に起動していた世代を選択して起動する．

#### 2. extlinux メニュー (`torii-chan` SBC / Orange Pi Zero 3)
1. HDMI ディスプレイまたは UART シリアルコンソールを接続して電源を投入する．
2. U-Boot のカウントダウン中に任意のキーを押し，extlinux 世代選択画面を表示する．
3. 過去の正常な世代エントリを選択して起動する (`/boot` は常に SD カード上の `NIXOS_SD` に保持されているため，HDD 側の不具合時でもメニューからブート可能)．

### 起動後の恒久化対応
旧世代を選択して起動しただけでは，次回の `nixos-rebuild switch` 時に再び不具合のある設定がビルド・適用されてしまう:
1. 不具合の原因となったコミットを特定し，`git revert` または設定修正を行う．
2. 修正した設定で再度スイッチを実行し，新たな健全世代を作成する:
   ```bash
   sudo nixos-rebuild switch --flake .#<hostname>
   ```

---

## 2. NixOS インストーラ USB によるレスキューマウントと nixos-enter

ブートローダー自体の破損，ストレージ設定の破壊，秘密情報の復号失敗により起動メニューから修復できない場合の復旧手順:

### Step 1: 事前準備
1. 公式 NixOS 最小インストーラ USB (またはカスタムインストーラ ISO) を用意し，対象マシンを USB ブートする．
2. インストーラ環境の root プロンプトに入る．

### Step 2: ストレージ構成別マウント手順

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

#### 構成 A: UEFI + GPT マシン (`BrokenPC`, `x1c7`, `kagutsuchi-sama`)
```bash
# ルートおよび EFI パーティションのマウント
mount /dev/disk/by-id/<root-partition> /mnt
mount /dev/disk/by-id/<efi-partition> /mnt/boot
```

#### 構成 B: レガシー BIOS 構成 (`shosoin-tan`: SSD + ZFS, `sando-kun`: HDD)
`shosoin-tan` は SSD 上に ext4 システム領域，2 台の HDD 上に ZFS Mirror (`tank-1tb`) を持つ．`sando-kun` は HDD (ext4) のみで ZFS は非搭載である:
```bash
# ルートおよび boot のマウント
# 例: shosoin-tan (SSD)
mount /dev/disk/by-id/ata-CT480BX500SSD1_1946E3D7A95A-part3 /mnt
mount /dev/disk/by-id/ata-CT480BX500SSD1_1946E3D7A95A-part2 /mnt/boot

# 例: sando-kun (HDD)
# mount /dev/disk/by-id/ata-ST9250320AS_5SW1VK4F-part3 /mnt
# mount /dev/disk/by-id/ata-ST9250320AS_5SW1VK4F-part2 /mnt/boot

# shosoin-tan 固有手順: 必要に応じて ZFS プールを代替ルート指定で強制インポート (sando-kun では不要)
zpool import -f -R /mnt tank-1tb
```

#### 構成 C: Orange Pi Zero 3 SBC (`torii-chan-hdd`)
ルートは外付け HDD (`NIXOS_HDD`)，`/boot` は SD カード (`NIXOS_SD`) に分かれている:
```bash
mount /dev/disk/by-label/NIXOS_HDD /mnt
mount /dev/disk/by-label/NIXOS_SD /mnt/boot
```

---

### Step 3: nixos-enter による環境突入と復旧作業

ターゲットシステムの完全なコンテキストで chroot 環境に入る:
```bash
nixos-enter --root /mnt
```

#### 復旧操作 1: SSH ホスト秘密鍵の整合性確認
暗号化シークレットの復号不全が原因の場合，SSH ホスト秘密鍵の存在とパーミッションを確認・修復する:
```bash
ls -la /etc/ssh/ssh_host_ed25519_key
# 権限が不正な場合は修正
chmod 600 /etc/ssh/ssh_host_ed25519_key

# ホストの SSH 公開鍵を確認し，hosts/<hostname>/default.nix の age.rekey.hostPubkey と突合
cat /etc/ssh/ssh_host_ed25519_key.pub
```

#### 復旧操作 2: ブートローダーの強制再インストール
ブートセクタの破損や EFI 変数の欠落が発生している場合，ブートローダーを強制再インストールする:
```bash
NIXOS_INSTALL_BOOTLOADER=1 /nix/var/nix/profiles/system/bin/switch-to-configuration boot
```

#### 復旧操作 3: 特定の健全世代をブート既定に設定
```bash
# 過去の健全な世代番号 (例: 35) を指定して boot 設定を更新
/nix/var/nix/profiles/system-35-link/bin/switch-to-configuration boot
```

#### 復旧操作 4: 設定の修正とリビルド (ネットワーク利用可能な場合)
```bash
cd /home/t3u/nix-config
nixos-rebuild boot --flake .#<hostname>
```

---

### Step 4: レスキュー環境からの脱出と再起動

すべての修復作業が完了したら，環境を抜けてアンマウントする:
```bash
# 1. nixos-enter を抜ける
exit

# 2. マウント解除
umount -R /mnt

# 3. ZFS をインポートしていた場合のみエクスポート (shosoin-tan のみ)
# zpool export tank-1tb

# 4. システム再起動
reboot
```

> [!CAUTION]
> **ZFS プール (`tank-1tb`) のエクスポート忘れに注意**
> `shosoin-tan` で ZFS プールをインポートした場合，レスキュー環境の再起動前に必ず `zpool export tank-1tb` を実行すること．全ホスト共通のベース設定で `boot.zfs.forceImportRoot = false` が有効であるため，エクスポートを怠ると次回起動時にプールがインポートできず Emergency Mode に陥る．

---

## 3. 実機全損・ストレージ全損時の完全復旧手順 (Bitwarden & Git からの再構築)

ハードウェアの物理故障，ストレージ換装，または管理端末を含む複数機被災時において，Bitwarden Vault と GitHub リポジトリから安全にマシンを再構築・復旧する手順．

### 前提条件と保管情報

| 保管先 | アイテム / パス | 内容・用途 |
| :--- | :--- | :--- |
| 公開 Git リポジトリ | `https://github.com/t3u-tsu/nix-config` | NixOS 構成宣言および再暗号化シークレット |
| Bitwarden Vault | `nix-config/agenix-master-key` | agenix-rekey Master age 秘密鍵 (`AGE-SECRET-KEY-1...`) |
| Bitwarden Vault | `nix-config/ssh/<hostname>` | 運用者 SSH 鍵 (`id_ed25519`) |
| Bitwarden Vault | `nix-config/nebula-ca/ca.key` | Nebula ルート CA 秘密鍵バックアップ |

### パターン A: 健全な管理端末から被災マシンを再構築する場合
健全な管理端末 (`BrokenPC` または `x1c7`) が手元にある場合の最短復旧フロー:

1. **新マシンのディスク初期化とマウント**:
   NixOS 公式 minimal インストーラ USB で実機を起動し，[新規ホスト追加手順](../operations/adding-a-host.md#3-新規ベアメタル導入手順-live-usb-クリーンインストール) に従いパーティショニングして `/mnt` (および `/mnt/boot`) へマウントする．
2. **SSH ホスト秘密鍵の事前生成**:
   ```bash
   sudo mkdir -p /mnt/etc/ssh
   sudo ssh-keygen -t ed25519 -N "" -f /mnt/etc/ssh/ssh_host_ed25519_key
   sudo chmod 600 /mnt/etc/ssh/ssh_host_ed25519_key
   cat /mnt/etc/ssh/ssh_host_ed25519_key.pub
   ```
3. **管理端末での公開鍵更新と再暗号化**:
   管理端末で `hosts/<hostname>/default.nix` の `age.rekey.hostPubkey` を得られた SSH 公開鍵 (`ssh-ed25519 ...`) へ更新し，再暗号化を実行して Git に push する:
   ```bash
   just secret-rekey
   git add hosts/<hostname>/default.nix secrets/rekeyed/hosts/<hostname>/
   git commit -m "fix(secrets): rotate host key for <hostname> recovery"
   git push origin feat/...
   ```
4. **新マシンでの private input デプロイキー復号**:
   新マシンのライブ環境でリポジトリを取得し，Step 2 で生成したホスト秘密鍵でデプロイキーを復号する:
   ```bash
   git clone https://github.com/t3u-tsu/nix-config
   cd nix-config

   sudo install -d -m 700 /root/.ssh
   sudo ssh-keyscan -t ed25519 github.com 2>/dev/null | sudo tee -a /root/.ssh/known_hosts >/dev/null

   sudo age -d -i /mnt/etc/ssh/ssh_host_ed25519_key \
     secrets/rekeyed/hosts/<hostname>/*-deploy_key.age \
     | sudo tee /root/.ssh/nix-config-private_deploy_key >/dev/null
   sudo chmod 600 /root/.ssh/nix-config-private_deploy_key

   sudo tee -a /root/.ssh/config >/dev/null <<'EOF'
   Host github-nix-config-private
     HostName github.com
     User git
     IdentityFile /root/.ssh/nix-config-private_deploy_key
     IdentitiesOnly yes
   EOF
   ```
5. **NixOS のインストールと再起動**:
   ```bash
   sudo nixos-install --flake .#<hostname>
   sudo reboot
   ```
   データサーバー (`shosoin-tan`) の場合は再起動後に [バックアップ運用 & ディザスタリカバリ (DR)](../operations/backup-and-restore.md) に従い Restic からデータを復元する．

### パターン B: 運用端末自体の全損・Live USB 単独でのブートストラップ
運用端末が手元になく，インストーラ USB と Bitwarden Vault のみからゼロベースで復旧する場合の手順:

1. **Live USB 上での Master 秘密鍵と運用者鍵の展開**:
   Web またはスマートフォン等で Bitwarden を開き，`nix-config/agenix-master-key` と `nix-config/ssh/<hostname>` を取得する．
   agenix-rekey が要求する tmpfs パス (`/run/user/1000/agenix/master-key.txt`) に Master 鍵を展開する:
   ```bash
   sudo mkdir -p /run/user/1000/agenix
   sudo chmod 700 /run/user/1000/agenix
   cat <<'EOF' | sudo tee /run/user/1000/agenix/master-key.txt >/dev/null
   AGE-SECRET-KEY-1...
   EOF
   sudo chmod 600 /run/user/1000/agenix/master-key.txt
   ```
2. **運用者 SSH 鍵と private input 設定**:
   ```bash
   sudo install -d -m 700 /root/.ssh
   cat <<'EOF' | sudo tee /root/.ssh/id_ed25519 >/dev/null
   -----BEGIN OPENSSH PRIVATE KEY-----
   ...
   -----END OPENSSH PRIVATE KEY-----
   EOF
   sudo chmod 600 /root/.ssh/id_ed25519
   sudo cp /root/.ssh/id_ed25519 /root/.ssh/nix-config-private_deploy_key

   sudo ssh-keyscan -t ed25519 github.com 2>/dev/null | sudo tee -a /root/.ssh/known_hosts >/dev/null
   sudo tee -a /root/.ssh/config >/dev/null <<'EOF'
   Host github-nix-config-private
     HostName github.com
     User git
     IdentityFile /root/.ssh/nix-config-private_deploy_key
     IdentitiesOnly yes
   EOF
   ```
3. **ディスク準備とホスト鍵事前生成**:
   ディスクをフォーマット・マウント後，恒久ホスト鍵を `/mnt/etc/ssh/ssh_host_ed25519_key` に生成する:
   ```bash
   sudo mkdir -p /mnt/etc/ssh
   sudo ssh-keygen -t ed25519 -N "" -f /mnt/etc/ssh/ssh_host_ed25519_key
   sudo chmod 600 /mnt/etc/ssh/ssh_host_ed25519_key
   ```
4. **リポジトリ取得と Live USB での再暗号化**:
   ```bash
   git clone https://github.com/t3u-tsu/nix-config
   cd nix-config

   # hosts/<hostname>/default.nix の age.rekey.hostPubkey を更新
   NEW_KEY=$(awk '{print $1, $2}' /mnt/etc/ssh/ssh_host_ed25519_key.pub)
   sed -i "s|age.rekey.hostPubkey = \"[^\"]*\";|age.rekey.hostPubkey = \"${NEW_KEY}\";|" hosts/<hostname>/default.nix

   # nix develop シェル内で再暗号化を実行
   nix develop --command just secret-rekey
   ```
5. **システムのインストールと再起動**:
   ```bash
   sudo nixos-install --flake .#<hostname>
   sudo reboot
   ```

---

## 関連ドキュメント
- [シークレット・認証トラブルシューティング](secrets-and-auth.md) — シークレット復号エラー，private input 認証失敗の復旧
- [ビルド・デプロイ障害トラブルシューティング](build-and-deploy.md) — ビルド・評価時の OOM，lock 不整合，権限昇格エラーの復旧
- [バックアップ運用 & ディザスタリカバリ (DR)](../operations/backup-and-restore.md) — Restic バックアップ運用，障害時リストア手順
- [ZFS 保守・リビルドガイド](../hardware/storage-zfs.md) — レガシー BIOS ブート，ZFS Mirror 保守・ディスク交換手順
- [Orange Pi Zero 3 ハードウェアガイド](../hardware/orange-pi-zero3.md) — Allwinner H618 SBC, U-Boot，低スペック制約
