# 新規ホスト追加手順

新しい NixOS マシンを追加し，暗号化シークレット，メッシュネットワーク，およびプライベート Flake 入力をセットアップして稼働させる標準手順．

## 1. 事前準備とチェックリスト

作業着手前の確認項目．

- [ ] マシンのハードウェア構成 (CPU アーキテクチャ，ストレージ構成，GPU，MAC アドレス)
- [ ] 割り当てる Nebula IP ([ネットワークアーキテクチャ](../architecture/network-topology.md) の台帳を参照)
- [ ] 適用するプロファイル (`desktop` / `tower-server` / `gateway` / `sbc`)
- [ ] Bitwarden の Master 秘密鍵 (`nix-config/agenix-master-key`) または有効な `BW_SESSION`
- [ ] 開発環境 (`nix develop` または direnv) の有効化

作業はトピックブランチを作成し，開発シェルに入って行う．
```bash
git checkout -b feat/add-<hostname>
nix develop  # direnv を使用していない場合
```

---

## 2. 既存 NixOS 環境への追加手順

### Step 1: ホストディレクトリの作成
テンプレートから複製し，`HOSTNAME` プレースホルダを置換する．
```bash
cp -r hosts/_template hosts/<hostname>
cd hosts/<hostname>
sed -i 's/HOSTNAME/<hostname>/g' default.nix README.md
```

実機で生成した `hardware-configuration.nix` をベースに，`hosts/<hostname>/hardware.nix` を編集してファイルシステムと swap を設定する．`hosts/<hostname>/services/nebula.nix` は，`my.networking.nebula.ip` ([ネットワークアーキテクチャ](../architecture/network-topology.md) の台帳で次の空き IP) と `groups` を実機の役割に合わせて編集する．

### Step 2: Flake へのホスト登録 ([flake/hosts.nix](../../flake/hosts.nix))
[flake/hosts.nix](../../flake/hosts.nix) に新しいホストのエントリを追加する．
```nix
<hostname> = mkLib.mkSystem {
  name = "<hostname>";
  system = "x86_64-linux"; # または "aarch64-linux"
  username = "t3u";
  profile = "tower-server"; # desktop | tower-server | gateway | sbc
};
```

### Step 3: ホスト公開鍵の登録と初期シークレットのステージング

1. 新マシンの SSH ホスト公開鍵 (`/etc/ssh/ssh_host_ed25519_key.pub`) を取得する．
   ```bash
   cat /etc/ssh/ssh_host_ed25519_key.pub
   # 出力例: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5...
   ```
2. `hosts/<hostname>/default.nix` に SSH ホスト公開鍵を登録する．
   ```nix
   age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5...";
   ```
3. ユーザーの初期パスワードハッシュをステージングする (root アカウントはパスワードを持たずロックされるため設定不要)．
   ```bash
   mkdir -p .secrets-staging/hosts/<hostname>
   mkpasswd -m yescrypt -s > .secrets-staging/hosts/<hostname>/user_password_hash
   ```
   (対話コマンド `just secret-set-host-password <hostname>` で直接 `secrets/master/` へ暗号化保存することも可能)
4. サーバー機で非常用帯域外アクセス (Cloudflare Tunnel) を有効化する場合は，Cloudflare Zero Trust で Tunnel を作成し，認証トークンをステージングする．
   ```bash
   echo -n "<cloudflared_token>" > .secrets-staging/hosts/<hostname>/emergency_ssh_token
   ```
   (詳細は [emergency-cf-ssh.md](emergency-cf-ssh.md) 参照)

### Step 4: Nebula 証明書の発行とシークレットの一括再暗号化

1. 管理者のオフライン CA ([scripts/nebula/nebula-rotate-ca.ysh](../../scripts/nebula/nebula-rotate-ca.ysh) の既定配置先: `~/.nebula-ca-10-0-0`) を用いてノード証明書を発行する．
   ```bash
   CA_DIR="${CA_DIR:-$HOME/.nebula-ca-10-0-0}"
   nebula-cert sign \
     -name "<hostname>" \
     -networks "10.0.0.X/24" \
     -groups "mgmt,..." \
     -ca-crt "$CA_DIR/ca.crt" \
     -ca-key "$CA_DIR/ca.key" \
     -out-crt "hosts/<hostname>/nebula.crt" \
     -out-key "$CA_DIR/<hostname>.key"
   ```
2. [scripts/nebula/nebula-lib.ysh](../../scripts/nebula/nebula-lib.ysh) の `FLEET` リストにエントリを追加する．
   ```ysh
   {name: '<hostname>', octet: X, groups: ['mgmt', ...]},
   ```
3. ノード秘密鍵をステージング領域に配置し，初期シークレットを一括で暗号化・再暗号化する．
   ```bash
   mv "$CA_DIR/<hostname>.key" .secrets-staging/hosts/<hostname>/nebula_key
   just secret-apply-staging
   ```
   このコマンドは `.secrets-staging/` 内の全平文を Master 鍵で暗号化して shred した後，`agenix rekey` を実行し，`secrets/rekeyed/hosts/<hostname>/` に当該ホスト専用の暗号化ファイル群 (パスワード，Nebula 鍵，deploy key 等) を生成する．

### Step 5: プライベート Flake 入力のブートストラップ
個人機密設定を管理するプライベートリポジトリ `nix-config-private` を flake input として参照する．初回の未適用状態では SSH エイリアス `github-nix-config-private` が未構成のため，そのままでは Flake 評価に失敗する．

新ホスト側 (root 権限) で初回ビルド前に一時的な SSH エイリアスを設定する．

```bash
# 新ホスト側で実行
mkdir -p /root/.ssh
chmod 700 /root/.ssh
ssh-keyscan -t ed25519 github.com 2>/dev/null | tee -a /root/.ssh/known_hosts >/dev/null

# deploy key の配置 (Step 4 で再暗号化された deploy_key.age をホスト秘密鍵で復号，または作業機からコピー)
sudo age -d -i /etc/ssh/ssh_host_ed25519_key \
  secrets/rekeyed/hosts/<hostname>/*-deploy_key.age \
  | sudo tee /root/.ssh/nix-config-private_deploy_key >/dev/null
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
初回の `nixos-rebuild switch` 完了後は `private-config.nix` が恒久的な設定を配置するため，一時ファイルは置換または削除できる．

### Step 6: 検証と事前ビルド
Flake は Git 追跡下のファイルのみを参照するため，変更をインデックスに追加してから検証する．
```bash
git add -A
nix flake check

# 一般ユーザー権限での事前ビルド (シンボリックリンクを残さない)
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel --no-link
```

### Step 7: 適用

新規ベアメタル機へ導入する場合は，後述の「[3. 新規ベアメタル導入手順 (Live USB クリーンインストール)](#3-新規ベアメタル導入手順-live-usb-クリーンインストール)」に従い，インストーラ USB からパーティショニング，鍵配置，`nixos-install` を実施する．

既存 NixOS マシンへ適用する場合は，対象環境に応じて実行する．

ローカルマシンの場合:
```bash
sudo nixos-rebuild switch --flake .#<hostname>
```
デスクトップ環境でエージェントが実行する場合は `pkexec --keep-cwd nixos-rebuild switch ...` を使用する．

リモートサーバーまたはヘッドレス機の場合:
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
   sudo mkdir -p /mnt/boot
   sudo mount /dev/nvme0n1p1 /mnt/boot         # ESP / ブートパーティション

   # Legacy BIOS 機の場合 (例):
   # sudo mount /dev/sda3 /mnt                 # ルートパーティション
   # sudo mkdir -p /mnt/boot
   # sudo mount /dev/sda2 /mnt/boot            # ブートパーティション
   ```

### Step 2: SSH ホスト鍵の事前生成とシークレットの rekey

agenix は起動時およびシステム activation 時に `/etc/ssh/ssh_host_ed25519_key` を用いて `/run/agenix/` 配下にシークレットを自動復号する．

```bash
# 恒久利用する SSH ホスト鍵をターゲット領域に事前生成
sudo mkdir -p /mnt/etc/ssh
sudo ssh-keygen -t ed25519 -N "" -f /mnt/etc/ssh/ssh_host_ed25519_key
sudo chmod 600 /mnt/etc/ssh/ssh_host_ed25519_key

# SSH ホスト公開鍵を取得
cat /mnt/etc/ssh/ssh_host_ed25519_key.pub
```

取得した SSH ホスト公開鍵 (`ssh-ed25519 ...`) を管理作業機の `hosts/<hostname>/default.nix` に `age.rekey.hostPubkey` として登録し，管理作業機側で `just secret-rekey` を実行して Git にコミットする．
これにより `secrets/rekeyed/hosts/<hostname>/` 配下に当該マシンの SSH ホスト鍵で復号可能な暗号化ファイル群が用意されるため，追加の秘密鍵コピーは不要である．

### Step 3: プライベート Flake 入力用 deploy key の配置

インストーラ環境 (ライブ環境の root 権限) からプライベートリポジトリ `nix-config-private` を取得できるよう，一時的な SSH 設定を配備する．

```bash
# ライブ環境の root SSH ディレクトリを準備
sudo install -d -m 700 /root/.ssh
sudo ssh-keyscan -t ed25519 github.com 2>/dev/null | sudo tee -a /root/.ssh/known_hosts >/dev/null

# deploy key を配置 (Step 2 で生成したホスト鍵で secrets/rekeyed/hosts/<hostname>/ 配下の deploy_key.age を復号，または作業機からコピー)
sudo age -d -i /mnt/etc/ssh/ssh_host_ed25519_key \
  secrets/rekeyed/hosts/<hostname>/*-deploy_key.age \
  | sudo tee /root/.ssh/nix-config-private_deploy_key >/dev/null
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

ターゲットホストの設定をビルド・インストールする．

```bash
# リポジトリを展開したディレクトリで実行
sudo nixos-install --flake .#<hostname>
```

インストール完了後，再起動する．
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
- [シークレット & 鍵ライフサイクル管理](secret-management.md) — agenix-rekey / Bitwarden 鍵管理と証明書運用
- [シークレット・認証トラブルシューティング](../troubleshooting/secrets-and-auth.md) — シークレット復号エラー，private input 認証失敗の復旧
