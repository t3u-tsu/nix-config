# 新規ホスト追加手順

新規マシンへ NixOS を導入し，暗号化シークレットとメッシュネットワークを設定してフリートへ参加させる手順．

## 1. 前提条件

[scripts/install/](../../scripts/install/) のスクリプトは， `ysh` や `age` が無い環境では `nix-shell` でこれらを導入してから処理を続行する．初回実行時は nixpkgs の取得にネットワークを要する．

対象機での作業は，実機コンソール直接または作業機から `ssh root@<target-ip>` で接続して進める．Live USB 環境では `sudo passwd root` 等で一時パスワードを設定し，`ip a` で IP アドレスを確認する．

### 作業前チェックリスト
- [ ] 適用プロファイルの選定: `desktop`, `tower-server`, `gateway`, `sbc`
- [ ] 割り当て Nebula IP の決定: [ネットワークアーキテクチャ](../architecture/network-topology.md) の台帳で空いている `10.0.0.0/24` 内のアドレス
- [ ] 対象機のネットワーク接続: 有線 LAN または Wi-Fi

---

## 2. 作業手順

### Step 1: ディスクの準備と SSH ホスト鍵の生成

作業場所: 対象機

agenix-rekey は対象機の SSH ホスト公開鍵でシークレットを暗号化するため，インストール前にホスト鍵を生成して公開鍵を控える．ホスト鍵は対象ディスクへ書き込むため，先にパーティショニングとマウントを済ませる．

#### 1.1 インストーラ環境の起動とパーティショニング
NixOS 公式の minimal インストーラ USB で実機を起動し，ネットワークを接続する．パーティションを作成し，フォーマットして `/mnt` へマウントする．

UEFI の場合:
```bash
sudo parted -s /dev/nvme0n1 -- mklabel gpt
sudo parted -s /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
sudo parted -s /dev/nvme0n1 -- set 1 esp on
sudo parted -s /dev/nvme0n1 -- mkpart primary ext4 512MiB 100%
sudo mkfs.fat -F 32 /dev/nvme0n1p1
sudo mkfs.ext4 /dev/nvme0n1p2

sudo mount --mkdir /dev/nvme0n1p2 /mnt
sudo mount --mkdir /dev/nvme0n1p1 /mnt/boot
```

BIOS の場合:
```bash
sudo parted -s /dev/sda -- mklabel msdos
sudo parted -s /dev/sda -- mkpart primary linux-swap 1MiB 8GiB
sudo parted -s /dev/sda -- mkpart primary fat32 8GiB 8.5GiB
sudo parted -s /dev/sda -- set 2 boot on
sudo parted -s /dev/sda -- mkpart primary ext4 8.5GiB 100%
sudo mkswap /dev/sda1 && sudo swapon /dev/sda1
sudo mkfs.fat -F 32 /dev/sda2
sudo mkfs.ext4 /dev/sda3

sudo mount --mkdir /dev/sda3 /mnt
sudo mount --mkdir /dev/sda2 /mnt/boot
```

`findmnt /mnt` で対象ディスクが `/mnt` にマウントされていることを確認する．`init-host-key.sh` は `/mnt` がマウントポイントでない場合に中断する．

#### 1.2 リポジトリの取得と SSH ホスト鍵の生成
リポジトリを取得し，スクリプトを実行して SSH ホスト鍵を生成する．
```bash
git clone https://github.com/t3u-tsu/nix-config.git
cd nix-config
sudo ./scripts/install/init-host-key.sh
```

`/mnt/etc/ssh/ssh_host_ed25519_key` が既に存在する場合は再生成せず，公開鍵のみを再表示する．画面に表示された公開鍵文字列は，Step 2 で作業機から SSH 経由で自動取得するか，手動で設定する．

---

### Step 2: ホスト定義の作成と Flake 登録

作業場所: 作業機

#### 2.1 トピックブランチの作成
```bash
git checkout -b feat/add-<hostname>
```

#### 2.2 テンプレートの複製と実機構成の自動取得
テンプレートディレクトリを複製し，ホスト名を置換する．
```bash
cp -r hosts/_template hosts/<hostname>
sed -i 's/HOSTNAME/<hostname>/g' hosts/<hostname>/default.nix hosts/<hostname>/README.md
```

対象機から SSH 経由でハードウェア構成とホスト公開鍵を自動取得する．
```bash
# 実機のハードウェア構成を出力して直接保存
ssh root@<target-ip> "nixos-generate-config --root /mnt --dir /tmp && cat /tmp/hardware-configuration.nix" > hosts/<hostname>/hardware.nix

# ホスト公開鍵を取得して default.nix に自動設定
TARGET_PUBKEY=$(ssh root@<target-ip> "cat /mnt/etc/ssh/ssh_host_ed25519_key.pub")
sed -i "s|# age.rekey.hostPubkey = \"SSH_HOST_PUBKEY\";|age.rekey.hostPubkey = \"$TARGET_PUBKEY\";|" hosts/<hostname>/default.nix
```

各ファイルを編集・確認する．
- `hosts/<hostname>/default.nix`: `age.rekey.hostPubkey` に公開鍵が設定されていることを確認する．
- `hosts/<hostname>/hardware.nix`: デバイスパスを `/dev/disk/by-id/` へ置き換えるなど，必要に応じて調整する．
- `hosts/<hostname>/services/nebula.nix`: 割り当てた Nebula IP とグループを設定する．
  ```nix
  my.networking.nebula.ip = "10.0.0.X";
  my.networking.nebula.groups = [ "mgmt" ];
  ```

#### 2.3 Flake へのホスト登録
[flake/hosts.nix](../../flake/hosts.nix) に新しいホストのエントリを追加する．
```nix
"<hostname>" = mkLib.mkSystem {
  name = "<hostname>";
  system = "x86_64-linux";
  username = "t3u";
  profile = "tower-server";
};
```

---

### Step 3: 暗号化シークレットの登録と再暗号化

作業場所: 作業機

Master 鍵を用いて初期シークレットを作成し，対象機向けに一括再暗号化する．

#### 3.1 ユーザー初期パスワードの設定
```bash
just secret-set-host-password <hostname>
```
対話プロンプトで入力したパスワードが yescrypt でハッシュ化され，`secrets/master/hosts/<hostname>/user_password_hash.age` に暗号化保存される．root アカウントはパスワードを持たずロックされるため，一般ユーザーのみ設定する．

#### 3.2 Nebula 証明書の発行と秘密鍵の取り込み
オフライン CA を用いてノード証明書を発行する．
```bash
CA_DIR="${CA_DIR:-$HOME/.nebula-ca}"
nebula-cert sign \
  -name "<hostname>" \
  -networks "10.0.0.X/24" \
  -groups "mgmt" \
  -ca-crt "$CA_DIR/ca.crt" \
  -ca-key "$CA_DIR/ca.key" \
  -out-crt "$CA_DIR/<hostname>.crt" \
  -out-key "$CA_DIR/<hostname>.key"
```

[scripts/nebula/nebula-lib.ysh](../../scripts/nebula/nebula-lib.ysh) の `FLEET` リストにエントリを追加する．`octet` は割り当てた IP の第 4 オクテットと一致させる．
```ysh
{name: '<hostname>', octet: X, groups: ['mgmt']},
```

証明書と秘密鍵を取り込むスクリプトを実行する．Bitwarden セッションが必要なため，開発シェル内で実行する．
```bash
ysh scripts/nebula/nebula-import-secrets.ysh
```
証明書を `hosts/<hostname>/nebula.crt` に配置し，ノード秘密鍵を `secrets/master/hosts/<hostname>/nebula_key.age` へ暗号化保存する．

#### 3.3 非常用帯域外アクセス トークンのステージング
サーバー機で Cloudflare Tunnel による帯域外アクセスを有効にする場合は，Cloudflare Zero Trust で Tunnel を作成し，トークンをステージングする．
```bash
mkdir -p .secrets-staging/hosts/<hostname>
echo -n "<cloudflared_token>" > .secrets-staging/hosts/<hostname>/emergency_ssh_token
just secret-apply-staging
```
詳細は [非常用 SSH アクセス運用マニュアル](emergency-cf-ssh.md) を参照する．

#### 3.4 ホスト向けシークレットの一括再暗号化
```bash
just secret-rekey
```
Master 秘密鍵を用いて，`secrets/rekeyed/hosts/<hostname>/` 配下に当該マシンの SSH ホスト鍵で復号可能な暗号化ファイル群を生成する．`*-deploy_key.age` もここに含まれ，Step 5 で使用する．

---

### Step 4: 事前検証

作業場所: 作業機

Flake は Git 管理下のファイルのみを参照するため，変更をインデックスに追加してから検証する．

```bash
git add -A
nix flake check --no-build
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel --no-link
```

検証完了後，変更をコミットして `feat/add-<hostname>` ブランチをリモートリポジトリへ push する．Step 5 の対象機はこのブランチを取得する．

---

### Step 5: インストールと初回起動

作業場所: 対象機

Step 4 で push した変更を取得し，プライベート Flake 入力用の deploy key を設定した上で，NixOS をインストールする．

#### 5.1 変更の取得
Step 1 で取得したリポジトリを更新し，ホスト定義を含むブランチへ切り替える．
```bash
cd nix-config
git fetch origin feat/add-<hostname>
git switch feat/add-<hostname>
```

#### 5.2 deploy key の設定
プライベートリポジトリから Flake 入力を取得できるよう，暗号化された deploy key をホスト鍵で復号して SSH エイリアスを設定する．
```bash
sudo ./scripts/install/setup-deploy-key.sh <hostname>
```

スクリプトは `/mnt/etc/ssh/ssh_host_ed25519_key` で `secrets/rekeyed/hosts/<hostname>/*-deploy_key.age` を復号し，`/root/.ssh/nix-config-private_deploy_key` に配置して `~/.ssh/config` へ `github-nix-config-private` エイリアスを追記する．`age` が無い環境では `nix-shell` で導入する．

インストーラ環境の `/root/.ssh` は RAM 上にあり，再起動で消える．起動後のシステムでは [nixos/base/private-config.nix](../../nixos/base/private-config.nix) が `/etc/ssh/ssh_config` と `/etc/ssh/ssh_known_hosts` を管理する．

#### 5.3 システムのインストールと再起動
```bash
sudo nixos-install --no-root-passwd --flake .#<hostname>
sudo reboot
```

`--no-root-passwd` は root パスワードの対話設定を省略する．root はロックされたままとなり，ログインは一般ユーザー `t3u` で行う．

---

## 3. 検証

インストール完了後，対象機が正常に稼働していることを検証する．

### 3.1 Nebula メッシュ接続の疎通確認
別ノードから対象機の Nebula IP 宛てに疎通を確認する．
```bash
ping -c 3 10.0.0.X
```
期待される出力:
```text
3 packets transmitted, 3 received, 0% packet loss
```

対象機上で Nebula サービスの状態を確認する．
```bash
systemctl status nebula@nebula0.service
```
期待出力:
```text
Active: active (running)
```

### 3.2 SSH 接続の確認
作業機から Nebula 経由で SSH ログインできることを確認する．
```bash
ssh t3u@10.0.0.X
```
パスワードまたは SSH 公開鍵によりシェルが起動することを確認する．

### 3.3 暗号化シークレットの復号確認
対象機上で agenix によりシークレットが復号されていることを確認する．
```bash
sudo ls -la /run/agenix/
```
`user_password_hash`, `nebula_key`, `deploy_key` 等のシンボリックリンクが存在し，対象デーモンや root から読み取り可能であることを確認する．

---

## 関連ドキュメント
- [目次](../README.md) — 全体ナビゲーション・目次
- [非常用 SSH アクセス運用マニュアル](emergency-cf-ssh.md) — Cloudflare Tunnel 経由の帯域外 SSH アクセス手順
- [リポジトリ全体アーキテクチャ](../architecture/overview.md) — リポジトリの層構成とモジュール評価フロー
- [ネットワークアーキテクチャ](../architecture/network-topology.md) — Nebula メッシュネットワーク，IP 体系，DNS 設計
- [シークレット & 鍵ライフサイクル管理](secret-management.md) — agenix-rekey / Bitwarden 鍵管理と証明書運用
- [シークレット・認証トラブルシューティング](../troubleshooting/secrets-and-auth.md) — シークレット復号エラー，private input 認証失敗の復旧
