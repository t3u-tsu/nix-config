# 新規ホスト追加手順

新しい NixOS マシンを追加し，暗号化シークレット，メッシュネットワーク，およびプライベート Flake 入力をセットアップして稼働させる手順 (SSOT)．

## 1. 事前準備とチェックリスト

作業着手前の確認項目:

- [ ] マシンのハードウェア構成 (CPU アーキテクチャ, ストレージ構成, GPU, MAC アドレス)
- [ ] 割り当てる Nebula IP ([ネットワークアーキテクチャ](../architecture/network-topology.md) の台帳を参照)
- [ ] 適用するプロファイル (`desktop` / `tower-server` / `gateway` / `sbc`)
- [ ] 管理者マシンの master 鍵 (`~/.config/sops/age/keys.txt`)
- [ ] 開発環境 (`nix develop` または direnv) の有効化

作業はトピックブランチを作成し，開発シェルに入って行う:
```bash
git checkout -b feat/add-<hostname>
nix develop  # direnv を使用していない場合
```

---

## 2. 既存 NixOS 環境への追加手順

### Step 1: ホストディレクトリの作成
テンプレートから複製し，`HOSTNAME` プレースホルダを置換する:
```bash
cp -r hosts/_template hosts/<hostname>
cd hosts/<hostname>
sed -i 's/HOSTNAME/<hostname>/g' default.nix README.md
```

実機で生成した `hardware-configuration.nix` をベースに，`hosts/<hostname>/hardware.nix` を編集してファイルシステムと swap を設定する．`hosts/<hostname>/services/nebula.nix` は，`my.networking.nebula.ip` ([ネットワークアーキテクチャ](../architecture/network-topology.md) の台帳で次の空き IP) と `groups` を実機の役割に合わせて編集する．

### Step 2: Flake へのホスト登録 ([flake/hosts.nix](../../flake/hosts.nix))
[flake/hosts.nix](../../flake/hosts.nix) に新しいホストのエントリを追加する:
```nix
<hostname> = mkLib.mkSystem {
  name = "<hostname>";
  system = "x86_64-linux"; # または "aarch64-linux"
  username = "t3u";
  profile = "tower-server"; # desktop | tower-server | gateway | sbc
};
```

### Step 3: パスワード初期化と SOPS 鍵の登録

1. 新マシンの SSH ホスト公開鍵 (`/etc/ssh/ssh_host_ed25519_key.pub`) からホスト age 公開鍵を取得する．
   ```bash
   ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
   # 出力例: age1...
   ```
2. [.sops.yaml](../../.sops.yaml) にホストのアンカーと creation rules を追加する (アンカー名 `<hostKey>` はホスト名の小文字・ハイフンをアンダースコアに変換したもの)．
   ```yaml
   keys:
     - &<hostKey> age1...
   creation_rules:
     - path_regex: secrets/hosts/<hostname>\.yaml$
       key_groups:
         - age:
             - *master_key
             - *<hostKey>
   ```
3. 初期パスワードを生成し，ホスト個別シークレットを作成する．`set-host-password.ysh` は新規ファイルを [.sops.yaml](../../.sops.yaml) の creation rule で暗号化するため，必ず手順 2 の登録後に実行する．
   ```bash
   SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt ysh scripts/set-host-password.ysh <hostname>
   ```
4. [.sops.yaml](../../.sops.yaml) の内容を既存シークレットへ反映する．
   ```bash
   SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops updatekeys secrets/hosts/<hostname>.yaml
   ```
5. サーバー機で非常用帯域外アクセス (Cloudflare Tunnel) を有効化する場合は，Cloudflare Zero Trust で Tunnel を作成し，`<hostKey>_cloudflared_ssh_token` を `secrets/hosts/<hostname>.yaml` に登録する (詳細は [emergency-cf-ssh.md](emergency-cf-ssh.md) 参照)．

### Step 4: Nebula 証明書の発行と登録

1. 管理者のオフライン CA ([scripts/nebula-rotate-ca.ysh](../../scripts/nebula-rotate-ca.ysh) の既定配置先: `~/.nebula-ca-10-0-0`) を用いてノード証明書を発行する．
   ```bash
   CA_DIR="${CA_DIR:-$HOME/.nebula-ca-10-0-0}"
   nebula-cert sign \
     -name "<hostname>" \
     -networks "10.0.0.X/24" \
     -groups "mgmt,..." \
     -ca-crt "$CA_DIR/ca.crt" \
     -ca-key "$CA_DIR/ca.key" \
     -out-crt "$CA_DIR/<hostname>.crt" \
     -out-key "$CA_DIR/<hostname>.key"
   ```
2. [scripts/nebula-lib.ysh](../../scripts/nebula-lib.ysh) の `FLEET` リストにエントリを追加する．
   ```ysh
   {name: '<hostname>', octet: X, groups: ['mgmt', ...]},
   ```
3. ノード証明書をシークレットへインポートする．
   ```bash
   SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt ysh scripts/nebula-import-secrets.ysh "$CA_DIR"
   ```

### Step 5: プライベート Flake 入力のブートストラップ
個人機密設定を管理するプライベートリポジトリ `nix-config-private` を flake input として参照する．初回の未適用状態では SSH エイリアス `github-nix-config-private` が未構成のため，そのままでは Flake 評価に失敗する．

新ホスト側 (root 権限) で初回ビルド前に一時的な SSH エイリアスを設定する:
```bash
# 新ホスト側で実行 (secrets/common.yaml 内の nix_config_private_deploy_key を一時配置)
mkdir -p /root/.ssh
chmod 700 /root/.ssh

# deploy key の配置
cat > /root/.ssh/nix-config-private_deploy_key <<'EOF'
... (deploy key 内容) ...
EOF
chmod 600 /root/.ssh/nix-config-private_deploy_key

cat >> /root/.ssh/config <<'EOF'
Host github-nix-config-private
  HostName github.com
  User git
  IdentityFile /root/.ssh/nix-config-private_deploy_key
  IdentitiesOnly yes
EOF
chmod 600 /root/.ssh/config
```
※初回の `nixos-rebuild switch` 完了後は `private-config.nix` が恒久的な設定を配置するため，一時ファイルは置換または削除できる．

### Step 6: 検証と事前ビルド
Flake は Git 追跡下のファイルのみを参照するため，変更をインデックスに追加してから検証する:
```bash
git add -A
nix flake check

# 一般ユーザー権限での事前ビルド (シンボリックリンクを残さない)
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel --no-link
```

### Step 7: 適用

新規ベアメタル機への導入:
後述の「[3. 新規ベアメタル導入手順 (Live USB クリーンインストール)](#3-新規ベアメタル導入手順-live-usb-クリーンインストール)」に従い，インストーラ USB からパーティショニング，鍵配置，`nixos-install` を実施する．

既存 NixOS マシンへの適用:
- ローカルマシン:
  ```bash
  sudo nixos-rebuild switch --flake .#<hostname>
  ```
  (デスクトップ環境でエージェントが実行する場合は `pkexec --keep-cwd nixos-rebuild switch ...` を使用可能)
- リモートサーバー / ヘッドレス機:
  ```bash
  nixos-rebuild switch --flake .#<hostname> --target-host t3u@10.0.0.X --sudo --ask-sudo-password
  ```

---

## 3. 新規ベアメタル導入手順 (Live USB クリーンインストール)

物理マシン (ベアメタル) への導入，またはディスク初期化を伴うクリーンインストールの手順．

### Step 1: ライブ環境の起動とディスク準備

1. NixOS 公式の minimal インストーラ USB で実機を起動し，ネットワーク (有線 LAN または Wi-Fi) を接続する．
2. 対象マシンの `hardware.nix` に合わせてパーティションを作成する (全データ消去)．
   - UEFI 機の場合 (GPT 例):
     ```bash
     sudo parted /dev/nvme0n1 -- mklabel gpt
     sudo parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
     sudo parted /dev/nvme0n1 -- set 1 esp on
     sudo parted /dev/nvme0n1 -- mkpart primary ext4 512MiB 100%
     sudo mkfs.fat -F 32 /dev/nvme0n1p1
     sudo mkfs.ext4 /dev/nvme0n1p2
     ```
   - Legacy BIOS 機の場合 (MBR 例):
     ```bash
     sudo parted /dev/sda -- mklabel msdos
     sudo parted /dev/sda -- mkpart primary linux-swap 1MiB 8GiB
     sudo parted /dev/sda -- mkpart primary fat32 8GiB 8.5GiB
     sudo parted /dev/sda -- set 2 boot on
     sudo parted /dev/sda -- mkpart primary ext4 8.5GiB 100%
     sudo mkswap /dev/sda1 && sudo swapon /dev/sda1
     sudo mkfs.fat -F 32 /dev/sda2
     sudo mkfs.ext4 /dev/sda3
     ```
3. ターゲット領域をマウントする．
   ```bash
   # UEFI 機の場合:
   sudo mount /dev/nvme0n1p2 /mnt              # ルートパーティション
   sudo mkdir -p /mnt/boot /mnt/var/lib/sops-nix
   sudo mount /dev/nvme0n1p1 /mnt/boot         # ESP / ブートパーティション

   # Legacy BIOS 機の場合 (例):
   # sudo mount /dev/sda3 /mnt                 # ルートパーティション
   # sudo mkdir -p /mnt/boot /mnt/var/lib/sops-nix
   # sudo mount /dev/sda2 /mnt/boot            # ブートパーティション
   ```

### Step 2: SSH ホスト鍵と SOPS age 秘密鍵の事前配置

`nixos-install` のシステム activation でシークレット復号が行われるため，事前に age 秘密鍵を配置しておく必要がある．

```bash
# 恒久利用する SSH ホスト鍵をターゲット領域に事前生成
sudo mkdir -p /mnt/etc/ssh
sudo ssh-keygen -t ed25519 -N "" -f /mnt/etc/ssh/ssh_host_ed25519_key

# age 公開鍵を取得して管理者の .sops.yaml に登録・updatekeys
ssh-to-age -i /mnt/etc/ssh/ssh_host_ed25519_key.pub

# ホスト用の age 秘密鍵を配置 (パーミッション 600 を厳守)
ssh-to-age -private-key -i /mnt/etc/ssh/ssh_host_ed25519_key \
  | sudo tee /mnt/var/lib/sops-nix/key.txt >/dev/null
sudo chmod 600 /mnt/var/lib/sops-nix/key.txt
```
> [!NOTE]
> 管理作業機から直接プロビジョニングする場合は，`~/.config/sops/age/keys.txt` (master 鍵) を一時的に `/mnt/var/lib/sops-nix/key.txt` へコピーして代用してもよい (初回起動後にホスト鍵へ置換)．

### Step 3: プライベート Flake 入力用 deploy key の配置

インストーラ環境 (ライブ環境の root 権限) からプライベートリポジトリ `nix-config-private` を取得できるよう，一時的な SSH 設定を配備する．

```bash
# ライブ環境の root SSH ディレクトリを準備
sudo install -d -m 700 /root/.ssh
sudo ssh-keyscan -t ed25519 github.com 2>/dev/null | sudo tee -a /root/.ssh/known_hosts >/dev/null

# deploy key を配置 (secrets/common.yaml 内の nix_config_private_deploy_key または作業機の鍵)
sudo tee /root/.ssh/nix-config-private_deploy_key >/dev/null <<'EOF'
-----BEGIN OPENSSH PRIVATE KEY-----
... (deploy key 内容) ...
-----END OPENSSH PRIVATE KEY-----
EOF
sudo chmod 600 /root/.ssh/nix-config-private_deploy_key

# 一時 SSH エイリアスを設定 (追記)
sudo tee -a /root/.ssh/config >/dev/null <<'EOF'
Host github-nix-config-private
  HostName github.com
  User git
  IdentityFile /root/.ssh/nix-config-private_deploy_key
  IdentitiesOnly yes
EOF

# 疎通確認
sudo ssh -T git@github-nix-config-private
```

### Step 4: システムのインストールと再起動

ターゲットホストの設定をビルド・インストールする:

```bash
# リポジトリを展開したディレクトリで実行
sudo nixos-install --flake .#<hostname>
```

インストール完了後，再起動する:
```bash
sudo reboot
```
初回起動後，Nebula メッシュ接続 (`10.0.0.X`) および SSH 経由でのログインを確認する．

---

## 関連ドキュメント
- [目次 (設計・運用ドキュメント)](../README.md) — 全体ナビゲーション・目次
- [非常用 SSH アクセス運用マニュアル (Cloudflare Tunnel)](emergency-cf-ssh.md) — Cloudflare Tunnel 経由の帯域外 SSH アクセス手順
- [リポジトリ全体アーキテクチャ](../architecture/overview.md) — リポジトリの層構成とモジュール評価フロー
- [ネットワークアーキテクチャ](../architecture/network-topology.md) — Nebula メッシュネットワーク，IP 体系，DNS 設計
- [シークレット & 鍵ライフサイクル管理](secret-management.md) — SOPS / age 鍵管理と証明書ローテーション
- [シークレット・認証トラブルシューティング](../troubleshooting/secrets-and-auth.md) — SOPS 復号エラー，private input 認証失敗の復旧
