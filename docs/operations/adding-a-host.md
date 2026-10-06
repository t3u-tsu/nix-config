# 新規ホスト追加手順 (Adding a New Host)

本ドキュメントは，本リポジトリに新しい NixOS マシンを追加し，暗号化シークレット，メッシュネットワーク，およびプライベート Flake 入力をセットアップして稼働させるための **完全な一元手順書 (Single Source of Truth)** である．

---

## 1. 事前準備とチェックリスト

新しいホストを追加する前に，以下を確認する．

- [ ] マシンのハードウェア構成（CPU アーキテクチャ，ストレージ構成，GPU，MAC アドレス）
- [ ] 割り当てる Nebula IP（[`docs/architecture/network-topology.md`](../architecture/network-topology.md) の台帳を参照）
- [ ] 適用するプロファイル（`desktop` / `tower-server` / `gateway` / `sbc`）
- [ ] 管理者マシンで master 鍵が利用可能であること（`~/.config/sops/age/keys.txt`）

作業はトピックブランチを作成して行う:
```bash
git checkout -b feat/add-<hostname>
```

---

## 2. ステップ・バイ・ステップ手順

### Step 1: ホストディレクトリの作成
テンプレートから複製し，プレースホルダを置換する:
```bash
cp -r hosts/_template hosts/<hostname>
cd hosts/<hostname>
sed -i 's/HOSTNAME/<hostname>/g' default.nix README.md services/nebula.nix
```

実機で生成した `hardware-configuration.nix` をベースに，`hosts/<hostname>/hardware.nix` を編集してファイルシステムと swap を設定する．

### Step 2: Flake へのホスト登録 (`flake/hosts.nix`)
`flake/hosts.nix` に新しいホストのエントリを追加する:
```nix
<hostname> = mkLib.mkSystem {
  name = "<hostname>";
  system = "x86_64-linux"; # または "aarch64-linux"
  username = "t3u";
  profile = "tower-server"; # desktop | tower-server | gateway | sbc
};
```

### Step 3: パスワード初期化と SOPS 鍵の登録
1. **初期パスワードの生成**:
   ```bash
   nix shell nixpkgs#mkpasswd nixpkgs#sops nixpkgs#jq -c bash scripts/set-host-password.sh <hostname>
   ```
2. **ホスト age 公開鍵の取得**:
   新マシンの SSH ホスト公開鍵（`/etc/ssh/ssh_host_ed25519_key.pub`）を age 鍵へ変換する:
   ```bash
   ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
   # 出力例: age1...
   ```
3. **`.sops.yaml` への登録**:
   `.sops.yaml` にホストのアンカーと creation rules を追加する:
   ```yaml
   keys:
     - &<hostname> age1...
   creation_rules:
     - path_regex: secrets/hosts/<hostname>\.yaml$
       key_groups:
         - age:
             - *master_key
             - *<hostname>
   ```
4. **鍵の同期**:
   ```bash
   sops updatekeys secrets/hosts/<hostname>.yaml
   ```

### Step 4: Nebula 証明書の発行と登録
1. **証明書の署名**:
   管理者のオフライン CA（通常 `~/.nebula-ca`）を用いてノード証明書を発行する:
   ```bash
   CA_DIR="${CA_DIR:-$HOME/.nebula-ca}"
   nebula-cert sign \
     -name "<hostname>" \
     -ip "10.0.0.X/24" \
     -groups "mgmt,..." \
     -ca-crt "$CA_DIR/ca.crt" \
     -ca-key "$CA_DIR/ca.key" \
     -out-crt "$CA_DIR/<hostname>.crt" \
     -out-key "$CA_DIR/<hostname>.key"
   ```
2. **クラスタ管理スクリプトへの登録**:
   `scripts/nebula-lib.sh` の `FLEET` 配列にエントリ（`<name>|<octet>|<groups>`）を追加する:
   ```bash
   "<hostname>|X|mgmt,..."
   ```
3. **シークレットへのインポート**:
   ```bash
   SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt bash scripts/nebula-import-secrets.sh "$CA_DIR"
   ```

### Step 5: プライベート Flake 入力のブートストラップ
本リポジトリは，個人機密設定を管理するプライベートリポジトリ `nix-config-private` を flake input として参照する．
通常は `nixos/base/private-config.nix` が SSH エイリアス `github-nix-config-private` を自動構成するが，**初回の未適用状態ではこの設定が存在しないため，そのままでは Flake 評価が失敗する**．

新ホスト側（root 権限）で初回ビルド前に一時的な SSH エイリアスを設定する:
```bash
# 新ホスト側で実行
mkdir -p /root/.ssh
cat >> /root/.ssh/config <<'EOF'
Host github-nix-config-private
  HostName github.com
  User git
  IdentityFile /root/.ssh/id_ed25519_deploy  # secrets/common.yaml 内の deploy key を一時配置
EOF
chmod 600 /root/.ssh/config /root/.ssh/id_ed25519_deploy
```
※初回の `nixos-rebuild switch` 完了後は `private-config.nix` が恒久的な設定を配置するため，一時ファイルは自動的に置換または安全に削除できる．

### Step 6: 検証と事前ビルド
Flake は Git 追跡下のファイルのみを参照するため，変更をインデックスに追加してから検証する:
```bash
git add -A
nix flake check

# 一般ユーザー権限での事前ビルド（シンボリックリンクを残さない）
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel --no-link
```

### Step 7: 適用
- **ローカルマシン**:
  ```bash
  sudo nixos-rebuild switch --flake .#<hostname>
  ```
  （※AI エージェントが実行する場合は，デスクトップ環境で承認を得たうえで `pkexec --keep-cwd nixos-rebuild switch ...` を使用可能）
- **リモートサーバー / ヘッドレス機**:
  リモートデプロイまたは手動適用:
  ```bash
  nixos-rebuild switch --flake .#<hostname> --target-host t3u@10.0.0.X --sudo --ask-sudo-password
  ```

---

## 関連ドキュメント
- [リポジトリ全体アーキテクチャ](../architecture/overview.md)
- [ネットワークトポロジと IP 台帳](../architecture/network-topology.md)
- [シークレット & 証明書管理](secret-management.md)
- [トラブルシューティング: 認証・シークレット](../troubleshooting/secrets-and-auth.md)
