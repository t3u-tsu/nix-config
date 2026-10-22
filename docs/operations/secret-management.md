# シークレット & 鍵ライフサイクル管理

SOPS（sops-nix），age，1Password，および Nebula 証明書による暗号化シークレットの管理方針，鍵モデル，更新手順，および失効・廃棄手順．

## 1. 鍵階層とアクセスモデル

最小権限の原則に基づき，3 種類の age 鍵を使い分ける．

```mermaid
graph TD
    Master["master_key（オフライン保管 / 1Password）<br>全シークレットの暗号化・復号・鍵更新"]
    HostKey["ホスト固有鍵（Host age keys）<br>/etc/ssh/ssh_host_ed25519_key から導出<br>/var/lib/sops-nix/key.txt"]
    UserKey["ユーザー鍵（User age keys）<br>~/.ssh/id_ed25519 から導出"]

    CommonSecret["secrets/common.yaml<br>全ホスト共通シークレット<br>（Nebula CA，デプロイ鍵 等）"]
    HostSecret["secrets/hosts/[hostname].yaml<br>各ホスト専用シークレット<br>（ユーザーパスワード，Nebula 秘密鍵 等）"]
    ServiceSecret["secrets/services/[service].yaml<br>サービス個別シークレット<br>（ホスト常駐用 / ユーザー端末用）"]

    Master -->|暗号化 / 復号| CommonSecret
    Master -->|暗号化 / 復号| HostSecret
    Master -->|暗号化 / 復号| ServiceSecret

    HostKey -->|共通分を復号| CommonSecret
    HostKey -->|自ホスト分を復号| HostSecret
    HostKey -->|該当サービス分を復号| ServiceSecret
    UserKey -->|署名・API 用を復号| ServiceSecret
```

| 鍵の種別 | 配置場所 | 権限範囲 | 用途 |
| :--- | :--- | :--- | :--- |
| **`master_key`** | 1Password / 管理者のオフライン端末 | 全ファイルの復号・暗号化 | 新ホスト追加，鍵のローテーション，暗号化ファイルの編集 |
| **ホスト鍵** | `/var/lib/sops-nix/key.txt` | `secrets/hosts/<hostname>.yaml`，`secrets/common.yaml`，および該当ホストの `secrets/services/*.yaml` | 起動時の自動復号，ホスト常駐サービス用クレデンシャルの読み込み |
| **ユーザー鍵** | `~/.ssh/id_ed25519` | `secrets/services/signing.yaml` および `secrets/services/conoha-vps-mcp.yaml` | コミット署名鍵，ConoHa API クレデンシャルの復号（デスクトップ環境） |

---

## 2. 秘密情報のファイル構成

- `secrets/common.yaml`: 全ホストで共有される共通シークレット．Nebula ルート CA 公開証明書（`nebula_ca`），`nix-config-private` 取得用 GitHub デプロイ鍵等を含む．
- `secrets/hosts/<hostname>.yaml`: ホスト個別のシークレット．ログインユーザーのハッシュ化パスワード，当該ホストの Nebula ノード秘密鍵等を含む．
- `secrets/services/<service>.yaml`: 用途別のサービスシークレット．Cloudflare API トークン（`ddns.yaml`），Restic（`backup.yaml`），Minecraft（`minecraft.yaml`），ConoHa API（`conoha-vps-mcp.yaml`），コミット署名鍵（`signing.yaml`）等を含む．

---

## 3. 日常のシークレット編集

シークレットの編集には `master_key` が必要である．環境変数 `SOPS_AGE_KEY_FILE` で秘密鍵パスを指定して `sops` コマンドを実行する:
```bash
# master 鍵の環境変数を指定して共通シークレットを編集
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops secrets/common.yaml

# ホスト個別シークレットの編集
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops secrets/hosts/<hostname>.yaml
```

---

## 4. Nebula 証明書のローテーション

Nebula ルート CA（`scripts/nebula-rotate-ca.ysh` の既定配置先: `~/.nebula-ca-10-0-0/ca.crt`）の有効期限は 10 年（`-duration 87600h`）であり，各ノード証明書もこれを継承する．鍵漏洩やノード追加・更新に伴う証明書管理の手順は以下の通りである:

```bash
CA_DIR="${CA_DIR:-$HOME/.nebula-ca-10-0-0}"

# 各ノードの証明書を署名後，SOPS へ一括インポート
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt ysh scripts/nebula-import-secrets.ysh "$CA_DIR"
```
※ CA 自体を更新する場合は，`ysh scripts/nebula-rotate-ca.ysh` で全ノードの証明書を再発行した上で，上記の `nebula-import-secrets.ysh` を用いて SOPS へ取り込む．
更新後は Git にコミットして各ホストへデプロイを適用することで，ダウンタイムなく新しい証明書へ切り替わる．

---

## 5. ホスト廃棄・再インストール時の鍵失効プロトコル

マシンの破棄や OS 再インストールに伴い SSH ホスト鍵が変更された場合は，古い鍵のアクセス権を剥奪してシークレットを再暗号化する．

1. `.sops.yaml` の編集: 該当ホストの公開鍵アンカー（`&<hostname> age1...`）および `creation_rules` を削除する．
2. 既存シークレットの再暗号化:
   ```bash
   SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops updatekeys secrets/hosts/<hostname>.yaml
   ```
3. 不要シークレットファイルの削除: ホストを完全破棄する場合は `git rm secrets/hosts/<hostname>.yaml` を実行する．
4. Nebula 台帳からの削除: `scripts/nebula-lib.ysh` の `FLEET` リストから該当ホストのエントリを削除する．

---

## 関連ドキュメント
- [目次（設計・運用ドキュメント）](../README.md)
- [ネットワークアーキテクチャ](../architecture/network-topology.md)
- [新規ホスト追加手順](adding-a-host.md)
- [非常用 SSH アクセス運用マニュアル（Cloudflare Tunnel）](emergency-cf-ssh.md)
- [トラブルシューティング: 認証・シークレット](../troubleshooting/secrets-and-auth.md)
