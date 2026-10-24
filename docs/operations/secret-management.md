# シークレット & 鍵ライフサイクル管理

agenix-rekey, age, Bitwarden，および Nebula 証明書による暗号化シークレットの管理方針，鍵モデル，運用手順，失効・廃棄手順．

## 1. 多層防御モデルとアクセス権限

作業端末が侵害された場合でもインフラ全体の権限奪取を防ぐため，Bitwarden 隔離保管，RAM tmpfs 一時展開，agenix-rekey による最小権限配布の多層防御境界を構築する．

```mermaid
graph TD
    subgraph Layer1 ["第 1 防御層: Bitwarden Vault (隔離保管)"]
        BW["フォルダ: nix-config/<br>・agenix-master-key (age 秘密鍵)<br>・ssh/ (ユーザー SSH 鍵)<br>・nebula-ca/ (CA 秘密鍵バックアップ)"]
    end

    subgraph Layer2 ["第 2 防御層: 作業端末 RAM (一時展開)"]
        Tmpfs["/run/user/[uid]/agenix/master-key.txt<br>(RAM tmpfs / chmod 0600 / trap 自動消去)"]
        BW -->|bw get item / notes| Tmpfs
    end

    subgraph Layer3 ["第 3 防御層: マスター暗号化データ & agenix-rekey"]
        MasterDir["secrets/master/<br>(Master 公開鍵で暗号化)"]
        Engine["agenix rekey<br>(Flake 依存関係から自動解決)"]
        Tmpfs --> Engine
        MasterDir --> Engine
    end

    subgraph Layer4 ["第 4 防御層: ターゲットホスト (最小権限)"]
        Rekeyed["secrets/rekeyed/[host]/<br>secrets/rekeyed-home/[host]/[user]/<br>(各ホスト・ユーザー鍵で再暗号化 / Git 管理)"]
        HostKey["/etc/ssh/ssh_host_ed25519_key"]
        UserKey["~/.ssh/id_ed25519"]
        SecretRun["/run/agenix/<br>(RAM 上に復号)"]
        Engine --> Rekeyed
        Rekeyed --> SecretRun
        HostKey --> SecretRun
        UserKey --> SecretRun
    end
```

| 鍵の種別 | 配置場所 | 権限範囲 | 用途 |
| :--- | :--- | :--- | :--- |
| Master 鍵 | Bitwarden (`nix-config/agenix-master-key`) / RAM tmpfs (`/run/user/<uid>/agenix/master-key.txt`) | 全マスター暗号化ファイルの復号・再暗号化 | 新ホスト追加，鍵の更新，マスターファイルの編集 |
| ホスト鍵 | `/etc/ssh/ssh_host_ed25519_key` (公開鍵は `hosts/<hostname>/default.nix` の `age.rekey.hostPubkey`) | 当該ホスト専用 (`secrets/rekeyed/<hostname>/*.age`) | 起動時の自動復号，ホスト常駐サービス用クレデンシャルの配置 (`/run/agenix/`) |
| ユーザー SSH 鍵 | Bitwarden (`nix-config/ssh/<hostname>`) / 開発端末 (`~/.ssh/id_ed25519`) | リモートホストへの SSH 接続，Git 操作，home-manager シークレットの復号 | 運用者認証，home-manager シークレットの配布，ディザスタリカバリ時の SSH 鍵復旧 |

### 1.1 Bitwarden 保管庫構造 (`nix-config/`)

Bitwarden 上のインフラ資格情報は，専用フォルダ `nix-config/` 配下に格納する．

```text
nix-config/                          # ルートフォルダ
├── agenix-master-key                # [セキュアメモ] AGE-SECRET-KEY-1... (agenix-rekey Master 鍵)
├── nebula-ca/                       # [サブフォルダ] オフライン CA 秘密鍵バックアップ
│   └── ca.key                       # [セキュアメモ] Nebula ルート CA 秘密鍵
└── ssh/                             # [サブフォルダ] 対外認証用 SSH 鍵
    ├── BrokenPC                     # [SSH キー] BrokenPC の id_ed25519 (秘密鍵・公開鍵)
    └── x1c7                         # [SSH キー] x1c7 の id_ed25519 (秘密鍵・公開鍵)
```

| アイテム | 種別 | 格納内容 | 説明 |
| :--- | :--- | :--- | :--- |
| `nix-config/agenix-master-key` | セキュアメモ | `AGE-SECRET-KEY-1...` | agenix-rekey の Master age 秘密鍵．Bech32 形式テキストとして保持する． |
| `nix-config/nebula-ca/ca.key` | セキュアメモ | `ca.key` | Nebula ルート CA 秘密鍵のディザスタリカバリ用バックアップ． |
| `nix-config/ssh/<hostname>` | SSH キー | `id_ed25519` (秘密鍵・公開鍵) | Bitwarden の SSH キーアイテム形式で保管し，端末復旧時に取り出す． |

### 1.2 RAM tmpfs 一時展開と自動消去

[scripts/secret.ysh](../../scripts/secret.ysh) および [scripts/agenix-bw-lib.ysh](../../scripts/agenix-bw-lib.ysh) は，作業時に Master 秘密鍵を RAM 上の tmpfs (`/run/user/<uid>/agenix/master-key.txt`) へパーミッション `0600` で展開する．シェルの `trap` (EXIT/INT/TERM) により，正常終了・エラー・シグナル割り込みを問わず一時ファイルは即時に自動削除される．ディスクへの秘密鍵書き込みは発生しない．

---

## 2. リポジトリ内シークレット構成

シークレットはファイルパスとディレクトリでアクセス境界を分離する．

```text
secrets/
├── master/                          # Master 鍵でのみ暗号化されたマスターファイル群
│   ├── common/                      # 全ホスト共通シークレット
│   │   └── deploy_key.age           # GitHub プライベートリポジトリ取得用 deploy key
│   ├── hosts/<hostname>/            # ホスト固有シークレット
│   │   ├── user_password_hash.age   # ユーザーパスワードハッシュ
│   │   ├── root_password_hash.age   # root パスワードハッシュ
│   │   ├── nebula_key.age           # Nebula メッシュ VPN ノード秘密鍵
│   │   └── emergency_ssh_token.age  # Cloudflare Tunnel 認証トークン (常駐サーバー機)
│   └── services/<service>/          # サービス固有シークレット
│       ├── backup/                  # Restic バックアップ (password.age, ssh_key.age)
│       ├── ddns/                    # Cloudflare DDNS (cloudflare_api.env.age)
│       ├── discord-bridge/          # Discord Bot トークン (bridge.env.age)
│       ├── signing/                 # Git コミット署名用 GPG 鍵 (gpg_private_key.age)
│       └── conoha-vps-mcp/          # ConoHa API 認証情報 (credentials.env.age)
├── rekeyed/                         # agenix rekey で自動生成されるホスト・ユーザー別 .age 群 (Git 管理)
│   ├── BrokenPC/
│   ├── home/<username>/             # home-manager シークレット (ユーザー SSH 鍵で復号)
│   ├── shosoin-tan/
│   └── ...
└── migration-manifest.json          # SOPS からの移行マニフェスト
```

`secrets/master/` と `secrets/rekeyed/` は `just secret-migrate` と `just secret-rekey` の実行後に生成される．移行前は `secrets/hosts/*.yaml` などの旧 SOPS ファイルが残る．

| 区分 | 対象パス | 管理方式 | 説明 |
| :--- | :--- | :--- | :--- |
| マスター暗号化データ | `secrets/master/**/*.age` | age 暗号化 (Master 公開鍵) | Master 鍵でのみ復号できる定義ファイル．Git 管理する． |
| ホスト別配布データ | `secrets/rekeyed/<hostname>/*.age` | age 暗号化 (ホスト公開鍵) | `agenix rekey` が出力する各ホスト専用暗号化ファイル (`<hash>-<secret名>.age`)．Git 管理し CI での純粋ビルドを維持する． |
| ユーザー別配布データ | `secrets/rekeyed-home/<hostname>/<username>/*.age` | age 暗号化 (ユーザー SSH 公開鍵) | home-manager の `age.secrets` 用暗号化ファイル (`<hash>-<secret名>.age`)．Git 管理する． |
| 平文公開データ | `nixos/networking/nebula/ca.crt`, `hosts/<hostname>/nebula.crt` | 平文ファイル | 暗号化不要な公開証明書データ． |
| ローカル自動生成 | Minecraft forwarding secret, RCON password | 起動時生成 | shosoin-tan のサービス起動時に `openssl rand` で生成し，Git 管理から除外する． |
| 一時ステージング | `.secrets-staging/` | 平文一時配置 (`.gitignore`) | Master 鍵を持たない環境で暗号化対象の平文を一時配置する領域．暗号化後に shred 破棄される． |

---

## 3. 日常のシークレット運用

シークレット操作は [justfile](../../justfile) または [scripts/secret.ysh](../../scripts/secret.ysh) を通じて実行する．

### 3.1 認証セッションの初期化

対話端末では，環境変数 `BW_SESSION` が未設定の場合にスクリプトが自動で `bw unlock` を対話実行する．非対話実行時は事前にセッションキーを環境変数に設定する．

```bash
# セッションキーを取得して環境変数に設定
export BW_SESSION=$(bw unlock --raw)

# またはワンショット実行
BW_SESSION=$(bw unlock --raw) just secret-rekey
```

### 3.2 マスターファイルの編集

マスター暗号化ファイルを直接編集する場合は `just secret-edit` を実行する．

```bash
# マスター暗号化ファイルを復号して編集
just secret-edit secrets/master/services/ddns/cloudflare_api.env.age

# ホスト別配布ファイルへ再暗号化して反映
just secret-rekey
```

### 3.3 ホストシークレットの再暗号化 (Rekey)

マスターファイルやホスト公開鍵の変更後は，全ホスト向けに再暗号化を実行する．

```bash
just secret-rekey

# キャッシュを無視して全ホストを強制的に再暗号化する場合
ysh scripts/secret.ysh rekey --force
```

### 3.4 平文ステージングの取り込み

外部クレデンシャルの追加や初期設定時は，平文ファイルを `.secrets-staging/` に一時配置し，Master 鍵で暗号化して取り込む．

```bash
# secrets/master/ に対応するパス構造で平文を配置
mkdir -p .secrets-staging/hosts/<hostname>
echo -n "<password_hash>" > .secrets-staging/hosts/<hostname>/user_password_hash

# 取り込み計画の事前検証 (dry-run)
ysh scripts/secret.ysh apply-staging --dry-run

# 暗号化，平文の shred 削除，および rekey を一括実行
just secret-apply-staging
```

### 3.5 環境診断

必要な CLI ツール，マニフェスト整合性，Bitwarden 接続状態，およびステージング状態を診断する．

```bash
ysh scripts/secret.ysh doctor
```

### 3.6 旧 SOPS からのデータ移行

SOPS 暗号化ファイルをマニフェスト [secrets/migration-manifest.json](../../secrets/migration-manifest.json) に基づいて移行する．

```bash
# 移行計画の確認
ysh scripts/secret.ysh migrate --dry-run

# マスターファイル群の暗号化生成 (既存ファイルはスキップ)
just secret-migrate
```

---

## 4. Nebula CA と証明書運用

Nebula ネットワークの暗号化通信に使用する証明書と秘密鍵を管理する．

### 4.1 オフライン CA 原則

Nebula ルート CA の秘密鍵 (`ca.key`) は，運用者のオフライン環境 (`~/.nebula-ca-10-0-0/ca.key`) にのみ保持し，リポジトリや稼働ホストには配置しない．
ディザスタリカバリ用バックアップは Bitwarden の `nix-config/nebula-ca/ca.key` に保管する．
ルート CA 公開証明書 (`ca.crt`) は機密性がないため，平文ファイル `nixos/networking/nebula/ca.crt` としてリポジトリにコミットする．

### 4.2 ノード証明書の発行と秘密鍵の登録

各ノードの証明書発行と秘密鍵暗号化の手順．

```bash
CA_DIR="${CA_DIR:-$HOME/.nebula-ca-10-0-0}"

# 1. オフライン CA でノード証明書を発行
nebula-cert sign \
  -name "<hostname>" \
  -networks "10.0.0.X/24" \
  -groups "mgmt,..." \
  -ca-crt "$CA_DIR/ca.crt" \
  -ca-key "$CA_DIR/ca.key" \
  -out-crt "hosts/<hostname>/nebula.crt" \
  -out-key "$CA_DIR/<hostname>.key"

# 2. ノード秘密鍵をステージング領域に配置して暗号化・rekey
mkdir -p .secrets-staging/hosts/<hostname>
mv "$CA_DIR/<hostname>.key" .secrets-staging/hosts/<hostname>/nebula_key
just secret-apply-staging
```

### 4.3 CA の一括ローテーション

ルート CA を再作成する場合は，[scripts/nebula-rotate-ca.ysh](../../scripts/nebula-rotate-ca.ysh) で新 CA と全ノードの証明書・鍵を一括生成し，公開証明書を平文配置した後にノード秘密鍵群をステージング経由で暗号化する．`just secret-apply-staging` は平文の暗号化と shred，全ホストの rekey をまとめて実行する．

---

## 5. ホスト廃棄・再インストール時の鍵失効プロトコル

ハードウェア破棄または OS 再インストールに伴い SSH ホスト鍵が変更された場合の対処手順．

### 5.1 ホスト破棄手順

ホストを完全に撤退させる場合の手順．

1. `hosts/<hostname>/` を削除し，[flake/hosts.nix](../../flake/hosts.nix) から該当エントリを削除する．
2. [scripts/nebula-lib.ysh](../../scripts/nebula-lib.ysh) の `FLEET` リストから該当ホストを削除する．
3. シークレット定義ファイルを削除する．
   ```bash
   rm -rf secrets/master/hosts/<hostname>
   rm -rf secrets/rekeyed/<hostname>
   ```
4. 再暗号化を実行する．破棄されたホスト向けの再暗号化ファイルがリポジトリから消去される．
   ```bash
   just secret-rekey
   ```

### 5.2 ホスト再インストール手順

OS 再インストール等で SSH ホスト鍵が更新された場合の手順．

1. 新しい SSH ホスト公開鍵から age 公開鍵を取得する．
   ```bash
   ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
   ```
2. `hosts/<hostname>/default.nix` の `age.rekey.hostPubkey` を更新する．
   ```nix
   age.rekey.hostPubkey = "age1...";
   ```
3. 再暗号化を実行する．agenix-rekey が新しいホスト公開鍵で `secrets/rekeyed/<hostname>/` 配下の全ファイルを再暗号化し，旧ホスト鍵による復号権限を失効させる．
   ```bash
   just secret-rekey
   ```
4. Git コミットを作成し，変更を適用する．

---

## 関連ドキュメント
- [目次 (設計・運用ドキュメント)](../README.md) — 設計・運用ドキュメント一覧
- [ネットワークアーキテクチャ](../architecture/network-topology.md) — ネットワーク構成とメッシュ VPN 仕様
- [新規ホスト追加手順](adding-a-host.md) — 新規ハードウェア・ノード追加時の詳細手順
- [非常用 SSH アクセス運用マニュアル (Cloudflare Tunnel)](emergency-cf-ssh.md) — Cloudflare Tunnel 経由の非常用アクセス手順
- [トラブルシューティング: 認証・シークレット](../troubleshooting/secrets-and-auth.md) — 鍵認証・復号失敗時の切り分けと対処
