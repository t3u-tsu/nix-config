# OpenTofu: ConoHa VPS リソース管理

torii-chan のフェイルオーバー VPS を
**ConoHa VPS**（GMO）上に宣言的に構築するための OpenTofu 設定です

## 前提

- [devenv](https://devenv.sh/) シェル内で `tofu` を使用する（`devenv.nix` で管理）
- プロバイダ: [gmo-internet/conohavps](https://registry.terraform.io/providers/gmo-internet/conohavps/latest)（ベータ版）
- 認証情報: ConoHa の API ユーザー（`secrets/services/conoha-vps-mcp.yaml` に SOPS で保管済み）

## 認証情報の注入

認証情報は環境変数から読み込む（ファイルに平文で書かないこと）。

```bash
# SOPS から ConoHa API 認証情報を注入
export CONOHAVPS_USER_ID=$(sops -d --extract '["OPENSTACK_USER_ID"]' secrets/services/conoha-vps-mcp.yaml)
export CONOHAVPS_PASSWORD=$(sops -d --extract '["OPENSTACK_PASSWORD"]' secrets/services/conoha-vps-mcp.yaml)
export CONOHAVPS_TENANT_ID=$(sops -d --extract '["OPENSTACK_TENANT_ID"]' secrets/services/conoha-vps-mcp.yaml)
# リージョンは省略可（デフォルト c3j1）。プロバイダは CONOHAVPS_REGION も参照する。
```

必須変数（`TF_VAR_*` で渡す）:

```bash
export TF_VAR_admin_password='<9-70文字、英大・英小・数字・記号を含む>'
export TF_VAR_ssh_public_key='ssh-ed25519 AAAA... t3u@BrokenPC'  # vps.nix と同じ鍵
```

## 使い方

```bash
cd terraform
tofu init     # プロバイダ取得（初回）
tofu fmt      # 整形
tofu validate # 構文チェック
tofu plan     # 変更計画の確認
tofu apply    # 適用（※ VPS 作成で料金発生。実行前にユーザー承認が必要）
tofu output -json torii_chan_addresses   # 割当 IP 確認（wanIp 確定用）
tofu destroy  # 全リソース削除（※ 料金停止。承認が必要）
```

- 変数のデフォルト値は `variables.tf` を参照（512MB プラン / 30GB ブートボリューム / Debian 12 仮 OS）
- `.terraform.lock.hcl` はコミット対象（プロバイダのバージョン固定）
- state ファイルは **ローカル管理**（`terraform.tfstate`、`.gitignore` で除外済み）。
  ConoHa オブジェクトストレージ（S3 互換 API）は容量契約が必要なため、リモートバックエンドは使用しない

## State 管理（ローカル運用）

state ファイル（`terraform.tfstate`）はローカルに保存し、`.gitignore` で除外する（未コミット）。

- **単一オペレータ・単一ホストでの運用を前提**とする
- **バックアップ**: `tofu apply` の前に `terraform.tfstate` のコピーを推奨
  （例: `cp terraform.tfstate terraform.tfstate.bak`）
- **ConoHa オブジェクトストレージの S3 バックエンドは使用しない**（容量契約が必要なため見送り）。
  将来必要になった場合は `backend.tf` を追加し、`tofu init -migrate-state` で移行する

## リソース一覧

- `conohavps_keypair.t3u` — SSH キーペア（全ホスト共通の t3u 公開鍵）
- `conohavps_securitygroup.torii_chan` + ルール — 22/tcp・4242/udp (Nebula Lighthouse)・ICMP・egress 全許可
- `conohavps_volume.boot` — 30GB ブートボリューム（`c3j1-ds02-boot`、Debian 12 展開）
- `conohavps_instance.torii_chan` — 512MB プラン（`g2l-t-c1m512`）

## NixOS インストールワークフロー

ConoHa 標準 OS では NixOS を直接選べないため、**rescue ISO 注入**方式で
ディスクを NixOS に置き換える（512MB プランのため nixos-anywhere は不可）。

```bash
# 1. VPS 作成（Debian 起動）
tofu apply

# 2. Debian への SSH 疎通確認（キーペアが入っているか）
ssh -i ~/.ssh/t3u root@<public_ip>

# 3. NixOS minimal ISO を取得し、ISO を注入して rescue ブート
./scripts/nixos-iso.sh install <instance_id> ./nixos-minimal.iso

# 4. ConoHa コントロールパネルの VNC コンソールで NixOS インストーラを操作
#    （ネットワークを静的 IP に設定 → parted/mkfs → nixos-generate-config
#      → nixos-install。詳細は hosts/torii-chan/README.md の手順を参照）

# 5. インストール完了後、ISO を排出して通常ブート
./scripts/nixos-iso.sh eject <instance_id>

# 6. 割当 IP を vps.nix の wanIp / wanGateway に反映して NixOS を適用
tofu output -json torii_chan_addresses
```

`scripts/nixos-iso.sh` は ConoHa 公開 API を直接叩く（Image API で ISO を作成・
アップロード、Compute API の `rescue`/`unrescue` で挿入・排出）。

サブコマンド:
- `install <instance_id> <iso_file>` — ISO を作成・アップロードし、サーバー停止 → rescue 挿入 → 起動
- `eject <instance_id>` — サーバー停止 → unrescue（ISO 排出）→ 起動
- `status <instance_id>` — インスタンス状態の確認（status / vm_state / task_state / addresses）

エッジケース対応:
- サーバーが既に停止中の場合は `os-stop` の 409 を許容して続行（冪等）
- API エラー時はレスポンス本文を表示（原因の切り分けが容易）
- 状態遷移の待機タイムアウトは `CONOHAVPS_WAIT_TIMEOUT` 環境変数で調整可（デフォルト 600 秒）

## 注意事項

- **ベータ版プロバイダ**: 機能・スキーマが予告なく変わる可能性がある
- **料金**: 512MB プランは月額 459 円。`apply` で即課金が始まる
- **admin_pass 変更はインスタンス再作成**（force new）になるため、apply 前に確定させる
- **destroy 時**: ボリューム・SG・キーペアも削除される（インスタンス削除後の残リソースに注意）
