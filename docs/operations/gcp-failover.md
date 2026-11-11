# Google Cloud フェイルオーバー運用手順書

物理エッジゲートウェイ (`torii-chan`) 障害時に Google Cloud 上で東京オンデマンド待機系 (`torii-chan-gcp`) へ切り替え，物理環境復旧後に切り戻す運用手順．

| 項目 | 要件・確認事項 |
| :--- | :--- |
| 対象ホスト | `torii-chan-gcp` (待機系), `torii-chan` (本番系物理 SBC), `torii-chan-gcp-us` (常時監視系) |
| 実行権限 | GCP プロジェクト管理者 (`roles/compute.admin`, `roles/iam.serviceAccountUser`)，作業機 sudo 権限 |
| 必要ツール | `tofu`, `gcloud`, `nixos-anywhere`, `deploy-rs`, `ysh` (`failover.ysh`), `ssh`, `curl` |
| 作業前チェックリスト | [ ] GCP アカウントおよび Google AI Pro 年間 $10 クレジット枠の有効化<br>[ ] `gcloud auth application-default login` による認証完了<br>[ ] Bitwarden (`nix-config/ssh/torii-chan`) からのホスト秘密鍵取得準備<br>[ ] 作業機 (`BrokenPC` 等) での Flake 評価完了 (`nix flake check`) |

---

## 1. 概要とアーキテクチャ

平時は拠点Tの物理 SBC (Orange Pi Zero 3) がエッジゲートウェイおよび Nebula メッシュ Lighthouse (`10.0.0.1:4242`) として稼働し，Minecraft ポート転送 (TCP 25565 -> `shosoin-tan` 10.0.0.4) を中継する．物理障害時のみ Google Cloud 東京リージョン (`asia-northeast1`) の `e2-micro` インスタンスをオンデマンド起動し，国内 5–15ms の低遅延で通信を引き継ぐ．

```mermaid
sequenceDiagram
    autonumber
    actor Admin as 管理者 / 監視デーモン
    participant SBC as 物理 torii-chan (障害)
    participant GCE as Compute Engine (torii-chan-gcp)
    participant CF as Cloudflare DNS
    participant Mesh as Nebula クラスターノード

    Note over SBC,Admin: 平時: 物理 SBC が稼働 (GCE は TERMINATED 停止状態)
    SBC-xAdmin: 物理ハード障害 / 停電検知 (連続3回失敗: 30秒)
    Admin->>GCE: gcloud compute instances start (または failover.ysh)
    Note over GCE: 10〜15秒で起動完了 (エフェメラル IP 割当)
    GCE->>GCE: agenix 秘密鍵自動復号 & Nebula / NAT 起動
    Admin->>CF: Cloudflare API で A レコードを GCE パブリック IP へ更新
    Mesh->>GCE: 10.0.0.1 経由でメッシュ通信を自動再開
    Note over GCE,Mesh: フェイルオーバー完了 (低遅延サービス維持)

    Note over SBC,Admin: --- 物理環境の復旧フェーズ (30回成功 & 10分滞留) ---
    Admin->>SBC: 物理 SBC の正常稼働と疎通を確認
    Note over Admin,GCE: STONITH フェンシング実行
    Admin->>GCE: gcloud compute instances stop (TERMINATED 確認)
    Note over GCE: 課金完全停止 ($0/時) & スプリットブレイン防止
    Admin->>CF: Cloudflare A レコードを物理拠点 WAN IP へ切戻し
    Mesh->>SBC: 物理 SBC 経由の通信へ復帰
```

---

## 2. 前提条件

### 2.1 GCP アカウントとクレジット枠
Google AI Pro プラン (学割) に付帯する年間 $10.00 の Google Cloud クレジット枠を利用する．平時は東京インスタンスを停止 (`TERMINATED`) 状態とし，10GB の `pd-standard` ディスク維持費 ($0.48/月 = $5.76/年) のみに抑える．残額 $4.24/年は有事のフェイルオーバー稼働時間 (約 271.8 時間 = 約 11.3 日) に充当する．

### 2.2 CLI ツールと認証
作業機 (`BrokenPC` 等) で Google Cloud SDK を初期化し，Application Default Credentials (ADC) を設定する．

```bash
# gcloud CLI ログイン
gcloud auth login

# OpenTofu 用 Application Default Credentials (ADC) の設定
gcloud auth application-default login

# デフォルトプロジェクトの設定
gcloud config set project <YOUR_GCP_PROJECT_ID>
```

### 2.3 必要な IAM 権限
OpenTofu による基盤構築および運用スクリプトの実行には，次の IAM ロールが必要である．

| ロール | 権限範囲 | 主な用途 |
| :--- | :--- | :--- |
| `roles/compute.admin` | Compute Engine リソースの完全制御 | インスタンス，ディスク，ファイアウォール構築および電源操作 |
| `roles/iam.serviceAccountUser` | サービスアカウントの借用 | インスタンスへのサービスアカウント割り当て |

実行専用の最小権限サービスアカウントを作成する場合は，`compute.instances.get`, `compute.instances.start`, `compute.instances.stop`, `compute.instances.reset` の権限を持つカスタムロールを定義する．

---

## 3. 初回基盤構築と OS 導入 (Day 0 / Day 1)

### Step 1: OpenTofu による GCE 基盤プロビジョニング
リポジトリの `terraform/` 配下で OpenTofu を初期化し，インフラを適用する．

```bash
cd terraform
tofu init
tofu apply \
  -var="gcp_project_id=<YOUR_GCP_PROJECT_ID>" \
  -var="gcp_region=asia-northeast1" \
  -var="gcp_zone=asia-northeast1-b" \
  -var="assign_us_watcher_public_ipv4=false" \
  -var="ssh_public_key=$(cat ~/.ssh/id_ed25519.pub)"
```

各設定変数の設計意図は次のとおりである．

| 変数名 | デフォルト値 | 設計意図と注意事項 |
| :--- | :--- | :--- |
| `gcp_project_id` | なし (必須) | リソースを配置する GCP プロジェクト ID． |
| `gcp_region` | `asia-northeast1` | 国内ユーザー向け低遅延 (5–15ms) を確保するため東京を選択． |
| `gcp_zone` | `asia-northeast1-b` | 東京リージョンのプライマリゾーン． |
| `boot_disk_size_gb` | `10` | ディスク維持費を $0.48/月に抑えるため 10GB (`pd-standard`) を指定． |
| `assign_us_watcher_public_ipv4` | `false` | 2024年2月以降の外部 IPv4 課金 ($0.005/時 = $43.80/年) を回避するため無効化． |
| `ssh_public_key` | `null` (要指定) | ブートストラップ時 (`nixos-anywhere`) にターゲット VM (Debian 12) の root 権限へ SSH ログインするための作業機公開鍵 (`$(cat ~/.ssh/id_ed25519.pub)`)．未指定の場合，`nixos-anywhere` が `Permission denied (publickey)` で失敗する． |

OpenTofu の出力から，割り当てられたインスタンス名とエフェメラル パブリック IP を確認する．

```bash
tofu output -json
```

### Step 2: nixos-anywhere による NixOS ブートストラップ
OpenTofu で作成されたインスタンスは一時的に Debian 12 ベースイメージで起動する．`nixos-anywhere` を用いて kexec 経由で NixOS を導入する．

`torii-chan-gcp` には `disko` 定義が組み込まれており，`nixos-anywhere` は生成された `diskoScript` を用いてターゲットディスク (`/dev/sda`) に自動で GPT パーティションテーブル (BIOS ブートパーティション + `nixos` ラベル付き ext4 ルートパーティション) を作成し，`/mnt` にマウントした上でインストールを行う．これにより 1GB RAM 機における tmpfs のメモリ枯渇 (OOM Kill) を防止する．

`torii-chan` の gateway ロールは共通のホスト名と暗号化シークレット (`secrets/rekeyed/hosts/torii-chan/`) を共有する．Bitwarden (`nix-config/ssh/torii-chan`) に保管された `torii-chan` の SSH ホスト秘密鍵 (`ssh_host_ed25519_key`) をブートストラップ時にディスクへ配備する．

```bash
# 作業機でブートストラップ用一時ディレクトリを作成
mkdir -p -m 700 /tmp/torii-chan-bootstrap/etc/ssh

# Bitwarden から取得した秘密鍵を配置
cat << 'EOF' > /tmp/torii-chan-bootstrap/etc/ssh/ssh_host_ed25519_key
-----BEGIN OPENSSH PRIVATE KEY-----
<Bitwarden の nix-config/ssh/torii-chan に保管された秘密鍵>
-----END OPENSSH PRIVATE KEY-----
EOF
chmod 600 /tmp/torii-chan-bootstrap/etc/ssh/ssh_host_ed25519_key

# nixos-anywhere による完全自動ブートストラップ実行 (Disko 自動実行)
nix run github:nix-community/nixos-anywhere -- \
  --flake .#torii-chan-gcp \
  --extra-files /tmp/torii-chan-bootstrap \
  root@<instance_public_ip>

# 一時鍵ファイルの削除
rm -rf /tmp/torii-chan-bootstrap
```

> **補足: 手動パーティショニングによる代替手順 (Disko を使用しない場合)**
> 何らかの理由で Disko を介さず手動でディスクを準備する場合は，フェーズを分割して実行する．
> ```bash
> # 1. kexec でインストーラを RAM 起動
> nix run github:nix-community/nixos-anywhere -- --phases kexec root@<instance_public_ip>
>
> # 2. kexec 環境へ SSH ログインし，ディスクを初期化・マウント
> ssh root@<instance_public_ip> << 'EOF'
> parted -s /dev/sda -- mklabel msdos mkpart primary ext4 1MiB 100% set 1 boot on
> mkfs.ext4 -F -L nixos /dev/sda1
> mount /dev/disk/by-label/nixos /mnt
> EOF
>
> # 3. インストールと再起動を実行
> nix run github:nix-community/nixos-anywhere -- \
>   --phases install,reboot \
>   --flake .#torii-chan-gcp \
>   --extra-files /tmp/torii-chan-bootstrap \
>   root@<instance_public_ip>
> ```

インストール完了後，インスタンスは自動再起動して NixOS で立ち上がる．共通ホスト鍵が配備されているため，`agenix` により Cloudflare DDNS 認証情報 (`cloudflare_api_env.age`) および Nebula 秘密鍵 (`nebula_key.age`) が自動復号される．

動作確認後，課金を停止するためインスタンスを停止状態へ移行する．

```bash
# 東京待機系インスタンスの停止 (TERMINATED)
gcloud compute instances stop torii-chan-gcp --zone=asia-northeast1-b
```

### Step 3: deploy-rs によるリモートプッシュデプロイ環境の確立
GCE `e2-micro` インスタンスの RAM は 1GB であり，ターゲット上で `nixos-rebuild` による Flake 評価やビルドを実行するとメモリ枯渇 (OOM Killer) によりプロセスが強制終了する．

プッシュ型デプロイツール `deploy-rs` を採用し，十分なメモリ (32GB RAM) を持つ作業機 (`BrokenPC` 等) で評価とビルドを完結させ，事前ビルド済みのクロージャを SSH 経由で転送する．ターゲット上での有効化処理は 50MB 未満のメモリで完了するため，1GB RAM 機でも OOM を確実に回避できる．

`flake/deploy.nix` における主要設定パラメータは次のとおりである．

| パラメータ | 設定値 | 設計意図 |
| :--- | :--- | :--- |
| `hostname` | `"torii-chan-gcp.t3u.uk"` | 物理 SBC (`torii-chan.t3u.uk`) との誤接続を防止するための専用識別名． |
| `sshUser` | `"t3u"` | リポジトリの SSH セキュリティ強化規則 (`PermitRootLogin = "no"`, `AllowUsers = [ "t3u" ]`) に準拠． |
| `interactiveSudo` | `true` | `wheelNeedsPassword = true` 環境において，昇格パスワードを対話的に受け付けて安全に実行． |
| `autoRollback` | `true` | デプロイ失敗またはネットワーク疎通途絶時に前世代へ自動切り戻し． |
| `magicRollback` | `true` | SSH 接続が切断された場合に即座にロールバックを実行． |

> **警告: スタンバイ時のデプロイおよび誤接続防止に関する注意事項**
> 平時において東京待機系インスタンスは停止 (`TERMINATED`) 状態であり，エフェメラル外部 IP は解放されている．また，本番ドメイン `torii-chan.t3u.uk` は稼働中の物理 SBC を指している．`flake/deploy.nix` では専用ホスト名 `torii-chan-gcp.t3u.uk` を指定することで，待機中に誤って `deploy .#torii-chan-gcp` を実行しても物理 SBC (`aarch64`) への誤配備が発生しないよう保護している．

待機系ノードへ設定変更を適用する運用手順:

```bash
# 1. 東京待機系インスタンスを一時起動
gcloud compute instances start torii-chan-gcp --zone=asia-northeast1-b

# 2. 割り当てられたエフェメラル外部 IP を取得
GCE_IP=$(gcloud compute instances describe torii-chan-gcp \
  --zone=asia-northeast1-b \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

# 3. deploy-rs の --hostname オプションでエフェメラル IP を指定してプッシュデプロイ
nix run github:serokell/deploy-rs -- .#torii-chan-gcp --hostname "$GCE_IP"

# 4. デプロイおよび動作確認完了後，課金を停止するためインスタンスを停止状態へ復帰
gcloud compute instances stop torii-chan-gcp --zone=asia-northeast1-b
```

---

## 4. フェイルオーバー運用と自動化 (Day 2)

### Step 4: scripts/gcp/failover.ysh による運用制御
リポジトリ付属の [scripts/gcp/failover.ysh](../../scripts/gcp/failover.ysh) は，手動操作およびデーモン自動監視を提供する YSH コントローラーである．

#### 4.1 コマンド体系と実行例

```bash
# 状態確認: GCP インスタンスの電源状態と物理 SBC への疎通を照会
./scripts/gcp/failover.ysh status

# 単体死活監視: 物理 SBC への ICMP / TCP ポート疎通を確認
./scripts/gcp/failover.ysh healthcheck --target torii-chan.t3u.uk --timeout 2

# フェイルオーバー開始: 東京インスタンスを起動し，Cloudflare DNS を更新
./scripts/gcp/failover.ysh start-failover

# フェイルバック開始: SBC 復旧確認，東京インスタンスを停止 (STONITH)，DNS を切戻し
./scripts/gcp/failover.ysh start-failback

# 監視デーモン起動: 24時間常時ループで障害検知と切り戻しを自動実行
./scripts/gcp/failover.ysh watch --interval 10 --failover-threshold 3 --failback-threshold 30 --min-dwell 600
```

#### 4.2 耐障害性および安全機構

1. **STONITH フェンシングによるスプリットブレイン防止**:
   切り戻し処理 (`start-failback`) において，物理 SBC への切り替え前に必ず東京インスタンスの停止 (`compute.instances.stop`) を発行し，GCP 上で `TERMINATED` または `STOPPED` 状態に達したことを確認する．停止確認に失敗した場合は切り戻し処理を中断し，同一 IP (`10.0.0.1`) や DNS レコードを両系が同時に奪い合うスプリットブレインを防止する．

2. **アンチフラッピング ヒステリシス (状態遷移制御)**:
   ネットワークの一時的な揺らぎによる短時間の頻繁な切り替えを抑制するため，非対称なしきい値を備えたステートマシンを実装している．
   - 障害検知は，プローブ失敗が 3 回連続 (約 36 秒 = 10 秒間隔 + 2 秒タイムアウト × 3 回) した場合のみ `FAILING_OVER` から `FAILOVER` へ移行する．
   - 復旧検知は，物理 SBC 復旧後，30 回連続成功 (約 360 秒 = 6 分間) かつ障害発生からの経過時間が最低滞留時間 (`min_dwell_sec`: デフォルト 600 秒 = 10 分間) を満たした場合のみ切り戻しを実行する．復旧監視中に 1 度でも失敗した場合は成功カウントを直ちに 0 にリセットする．

3. **カーネル `flock` ロックによる排他制御**:
   デーモンループの監視サイクルと手動 CLI 操作や MCP ツール呼び出しの衝突を防ぐため，ファイル記述子ロック (`/var/lock/gcp-failover.lock` または `/tmp/gcp-failover.lock`) を用いて直列実行を保証する．

4. **自己プローブ防止およびプローブエンドポイント分離**:
   フェイルオーバーによって Cloudflare DNS の `torii-chan.t3u.uk` が東京 GCE インスタンスを指すように切り替わった後，監視デーモンが自分自身を ping して「物理 SBC が復旧した」と誤認する無限フラッピングループを防止する．物理 SBC 専用のプローブターゲット (`torii-chan-sbc.t3u.uk`)，または状態ファイルに保存された直前の物理 WAN IP (`saved_wan_ip`) を優先してプローブし，解決された IP が GCE インスタンスの外部 IP と一致する場合はプローブおよび DNS 上書きを自動的に拒否・遮断する．

### Step 5: AI 支援 MCP サーバーによる運用操作
[home/desktop/dev-tools/ai-tools/gcp-failover-mcp.nix](../../home/desktop/dev-tools/ai-tools/gcp-failover-mcp.nix) により，AI エージェント (CodeWhale, Antigravity 等) から直接フェイルオーバー設備の電源・状態を照会・制御できる．

> **注意: MCP サーバーの責務範囲とフェイルオーバースクリプトとの関係**
> - **`gcp-failover-mcp` (IaaS 電源制御ツール)**:
>   Compute Engine インスタンスの電源起動 (`start`)，停止 (`stop`)，状態照会 (`status`) のみに特化している．Cloudflare DNS レコードの更新や，物理 SBC の死活プローブ，アンチフラッピング判定，排他ロック制御は行わない．
> - **`scripts/gcp/failover.ysh` (統合オーケストレーター)**:
>   GCE 電源操作に加え，Cloudflare DNS の A レコード自動切り替え，物理 SBC 死活監視，最低滞留時間 (ヒステリシス) 監視，STONITH フェンシング，排他ロック (`flock`) によるエンドツーエンドの自動制御を提供する．

#### 5.1 MCP 設定の確認
Home Manager により `~/.codewhale/mcp.json` へ自動構成される．

```json
{
  "servers": {
    "gcp-failover-mcp": {
      "command": "gcp-failover-mcp",
      "args": [],
      "enabled": true
    }
  }
}
```

#### 5.2 提供ツール一覧

| ツール名 | 引数 | 動作内容 |
| :--- | :--- | :--- |
| `gcp_failover_status` | `instance`, `zone` | インスタンスの電源状態 (`RUNNING` / `TERMINATED`)，外部 IP，ゾーン，ディスク情報を照会． |
| `gcp_failover_start` | `instance`, `zone` | 東京フェイルオーバーインスタンスを起動し，エフェメラル IP を割り当て (IaaS 電源起動のみ．DNS は変更しない)． |
| `gcp_failover_stop` | `instance`, `zone` | 東京フェイルオーバーインスタンスを停止し，コンピュート課金を遮断 (IaaS 電源停止のみ．DNS は変更しない)． |

AI エージェントへの適切な指示プロンプト例:
- 状態・IP 照会:
  - 「torii-chan-gcp の現在の稼働状態と外部 IP を確認して」
- デプロイ・メンテナンス時の一時起動・停止:
  - 「deploy-rs で設定を反映するため，torii-chan-gcp インスタンスを一時起動して」
  - 「デプロイが完了したため，課金を停止するために torii-chan-gcp を停止して」
- 完全な自動フェイルオーバー / 切り戻し (DNS 連携必須):
  - 「物理 SBC 障害によりサービスを切り替えるため，`./scripts/gcp/failover.ysh start-failover` を実行して」
  - 「物理 SBC が復旧したため，`./scripts/gcp/failover.ysh start-failback` を実行して切り戻して」

> **警告: MCP ツール単体実行時の DNS 切り替え非対応**
> 物理 SBC 障害時に `gcp_failover_start` を実行しただけでは，Cloudflare DNS が切り替わらないため外部通信 (Minecraft 等) は復旧しない．DNS の自動切り替えを含む障害対応時は必ず `./scripts/gcp/failover.ysh start-failover` を使用すること．

---

## 5. 事後検証

各フェーズの完了時または障害訓練時に次の検証コマンドを実行し，期待出力を確認する．

### 5.1 GCE 電源状態の確認
平時はインスタンスが停止し，課金が発生していないことを確認する．

```bash
gcloud compute instances describe torii-chan-gcp --zone=asia-northeast1-b --format="get(status)"
```
期待出力:
```text
TERMINATED
```

### 5.2 物理 SBC 死活監視の確認
作業機から物理 SBC の疎通を確認する．

```bash
./scripts/gcp/failover.ysh healthcheck --target torii-chan.t3u.uk --timeout 2
```
期待出力:
```text
[INFO]  Health check PASSED for torii-chan.t3u.uk: ICMP ping alive (rtt=... ms)
```

### 5.3 Cloudflare DNS 解決の確認
DNS レコードが稼働側ノードのパブリック IP を指していることを確認する．

```bash
dig +short torii-chan.t3u.uk
dig +short mc.t3u.uk
```
期待出力:
- 平時: 物理拠点の固定 / 動的グローバル IP
- フェイルオーバー時: GCP GCE インスタンスのエフェメラル パブリック IP

### 5.4 Nebula メッシュ接続の確認
内部メッシュ Lighthouse への疎通を確認する．

```bash
ping -c 3 10.0.0.1
```
期待出力:
```text
3 packets transmitted, 3 received, 0% packet loss
```

### 5.5 Minecraft ポート転送 (TCP 25565) の疎通確認
外部から TCP 25565 ポートへの接続が受け付けられることを確認する．

```bash
nc -z -v -w 5 torii-chan.t3u.uk 25565
```
期待出力:
```text
Connection to torii-chan.t3u.uk 25565 port [tcp/*] succeeded!
```

---

## 関連ドキュメント
- [目次](../README.md) — 全ドキュメントの索引
- [GCP コストおよび遅延分析](../architecture/gcp-cost-analysis.md) — 東京オンデマンド構成と米国常時構成の料金試算および遅延比較
- [ネットワークアーキテクチャ](../architecture/network-topology.md) — ネットワーク構成とメッシュ VPN 仕様
- [Orange Pi Zero 3 ハードウェア仕様](../hardware/orange-pi-zero3.md) — 物理 SBC のハードウェア諸元と構成
- [Terraform モジュール仕様](../../terraform/README.md) — Google Cloud フェイルオーバー用 OpenTofu 定義
- [torii-chan ホスト仕様](../../hosts/torii-chan/README.md) — エッジゲートウェイの共通設定とターゲット一覧
- [暗号化シークレット管理](secret-management.md) — agenix-rekey によるシークレット暗号化とホスト鍵管理
