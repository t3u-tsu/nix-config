# ネットワーク障害トラブルシューティング

本ドキュメントは，Nebula メッシュ VPN の不通障害，ルータの NAT Loopback 非対応による LAN 内アクセス遮断，および SSH 遮断発生時の物理コンソール経由での復旧手順を記述する．

---

## 1. Nebula メッシュ不通時の調査

### 現象・エラーメッセージ
- `nebula0` 仮想ネットワークインターフェースが存在しない，またはリンクが down している．
- 他のノード（`10.0.0.x`）や Lighthouse（`10.0.0.1`）宛ての ping / SSH がタイムアウトする．
- `journalctl -u nebula@nebula0.service` に以下のエラーが記録される:
  - `Handshake message received was invalid`
  - `Certificate has expired`
  - `Cannot authenticate: certificate expired or not yet valid`
  - `Failed to listen on udp/4242: address already in use`

### 原因
1. **証明書の有効期限切れ**: ルート CA は 10 年有効だが，各ノードの証明書は **1 年有効** である．有効期限を過ぎるとハンドシェイクが即座に拒否される．
2. **Lighthouse（`torii-chan`）のポート不通**: UDP 4242 番ポートがルータのポートフォワード未設定，ConoHa セキュリティグループの制限，または DDNS（`torii-chan.t3u.uk`）の解決先誤りによって遮断されている．
3. **証明書メタデータの不一致**: `scripts/nebula-lib.sh` の `FLEET` 定義（IP，グループ）と異なる内容で証明書が署名されている．
4. **MTU 不一致**: 回線経路（モバイル回線等）の制約によりパケットが断片化・ドロップしている（本環境の標準 MTU は 1320）．

### 切り分け・復旧手順

#### Step 1: サービス状態とログの確認
```bash
systemctl status nebula@nebula0.service
journalctl -u nebula@nebula0.service -e --no-pager
```

#### Step 2: 証明書の検証（`nebula-cert print`）
配備されている証明書の内容と有効期限を確認する:
```bash
sudo nebula-cert print -path /run/secrets/<hostkey>_nebula_cert
sudo nebula-cert print -path /run/secrets/nebula_ca
```
- `Not After`: 有効期限が切れていないか確認．
- `Ips`: [`docs/architecture/network-topology.md`](../architecture/network-topology.md) の IP 割当と一致しているか確認．
- `Groups`: 必要な通信グループ（`mgmt`, `app` 等）が付与されているか確認．

#### Step 3: Lighthouse の外部疎通確認
クライアント側から Lighthouse の名前解決と UDP ポート疎通を確認する:
```bash
# DDNS の A レコード確認
dig +short torii-chan.t3u.uk

# UDP 4242 番ポートの疎通確認
nc -zvu torii-chan.t3u.uk 4242
```

#### Step 4: 証明書の再署名と再配布
証明書の期限切れまたは不整合が原因の場合，管理端末の CA 鍵（`~/.nebula-ca/`）から再署名を行う:
```bash
# 1. 単一ノード証明書の再署名
nix shell nixpkgs#nebula -c nebula-cert sign \
  -name "<hostname>" \
  -networks "10.0.0.<octet>/24" \
  -groups "<groups>" \
  -ca-crt ~/.nebula-ca/ca.crt \
  -ca-key ~/.nebula-ca/ca.key \
  -out-crt ~/.nebula-ca/<hostname>.crt \
  -out-key ~/.nebula-ca/<hostname>.key

# 2. SOPS へのインポート（master 鍵を使用）
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt bash scripts/nebula-import-secrets.sh

# 3. コミットと各ホストへのデプロイ
git add secrets/
git commit -m "fix(nebula): refresh certificate for <hostname>"
```

---

## 2. ルータの NAT loopback 非対応による LAN 内アクセス不能と local-network.nix

### 現象・エラーメッセージ
宅内 LAN の Wi-Fi や有線 LAN に接続された端末から，パブリックドメイン（`torii-chan.t3u.uk` や `mc.t3u.uk`）へアクセスしようとすると接続がタイムアウトまたは拒否される．一方，外部インターネット（LTE / テザリング等）からは正常にアクセスできる．

### 原因
宅内に設置されているルータが **NAT Loopback（ヘアピン NAT）** に対応していない．このため，LAN 内のノードから自ルータの WAN 側グローバル IP 宛てに送られたパケットが，LAN 内のエッジゲートウェイ（`torii-chan`: `192.168.0.128`）へ正しく転送されずルータ内部で破棄される．

### 対策・復旧手順

#### 対策 1: `local-network.nix` モジュールの有効化
宅内 LAN に常設されるサーバー群（`shosoin-tan`, `kagutsuchi-sama`, `sando-kun` 等）の `hosts/<hostname>/default.nix` において，[`nixos/networking/local-network.nix`](../../nixos/networking/local-network.nix) を有効化する:

```nix
# hosts/<hostname>/default.nix
my.networking.local-network.enable = true;
```

これにより，システム内の `/etc/hosts` に `192.168.0.128 torii-chan.t3u.uk` が静的に登録され，ルータを経由せず LAN 内直接通信が行われる．また `/etc/gai.conf` で IPv4 優先接続が設定される．

#### 対策 2: 一時的な hosts 上書き（手動）
設定反映前の緊急対応として，一時的に手動で解決エントリを追加する:
```bash
sudo sh -c 'echo "192.168.0.128 torii-chan.t3u.uk" >> /etc/hosts'
```

> [!WARNING]
> モバイルラップトップ（`x1c7`）などの外出先へ持ち出す端末では，宅外で `torii-chan.t3u.uk` に接続できなくなるため，`local-network.enable` を有効化してはならない．

---

## 3. SSH 接続が拒否された場合の物理コンソール・ローカル接続手順

### 現象・エラーメッセージ
LAN 内の別端末から SSH 接続を試行した際，以下のエラーとなり接続できない:
```text
ssh: connect to host 192.168.0.X port 22: Connection refused
```

### 原因
本リポジトリのタワーサーバー群（`tower-server` プロファイル）およびゲートウェイでは，セキュリティ強化のため [`nixos/profiles/tower-server/security.nix`](../../nixos/profiles/tower-server/security.nix) において:
```nix
networking.firewall.allowedTCPPorts = lib.mkForce [ ];
```
が設定されている．SSH ポート 22 は **Nebula インターフェース（`nebula0`, `trustedInterfaces`）経由でのみ許可** されており，LAN 側の物理インターフェースからはポート 22 へのアクセスがファイアウォールで遮断されている．このため，Nebula が停止すると物理 LAN からの SSH は一切不可となる．

### 物理コンソール経由での復旧手順

```mermaid
sequenceDiagram
    autonumber
    actor Admin as 管理者
    participant PC as 物理マシン (コンソール)
    participant FW as ファイアウォール (iptables)
    participant Term as 作業端末 (LAN)

    Admin->>PC: ディスプレイ & キーボードを直接接続
    Admin->>PC: TTY1 でログイン (t3u / root)
    Admin->>PC: sudo iptables -I INPUT -p tcp --dport 22 -j ACCEPT
    Note over PC,FW: 一時的に LAN ポート 22 を開放
    Admin->>Term: 作業端末へ戻る
    Term->>PC: ssh t3u@192.168.0.X (LAN 経由ログイン成功)
    Term->>PC: nebula@nebula0 障害調査・修復
    Term->>PC: sudo nixos-rebuild switch --flake .#hostname
    Note over PC,FW: ファイアウォールが安全な状態へ復元
```

#### Step 1: 物理コンソール（TTY）の接続とログイン
1. 対象マシンに物理ディスプレイ（HDMI/DP）と USB キーボードを接続する．
2. 画面にローカルコンソール（TTY）を表示し，初期セットアップ時に設定したパスワードでログインする:
   - ユーザー: `t3u` または `root`
   - ※画面が真っ暗な場合は `Ctrl+Alt+F1` または `Ctrl+Alt+F2` を押す．

#### Step 2: 一時的なファイアウォール開放
作業端末から快適に操作できるよう，メモリ上のみで一時的にポート 22 を許可する（再起動や `switch` で自動的にリセットされるため安全）:
```bash
sudo iptables -I INPUT -p tcp --dport 22 -j ACCEPT
```

#### Step 3: 作業端末からのリモート復旧
作業端末から LAN IP（`192.168.0.X`）宛てに SSH 接続し，Nebula サービスを修復する:
```bash
# 作業端末から実行
ssh t3u@192.168.0.X

# Nebula ログ確認と再起動
sudo systemctl restart nebula@nebula0.service
sudo journalctl -u nebula@nebula0.service -e
```

#### Step 4: 恒久設定の再適用
原因を解消した後，通常通り設定を switch してファイアウォールを元のセキュアな状態に戻す:
```bash
sudo nixos-rebuild switch --flake .#<hostname>
```

---

## 関連ドキュメント
- [ネットワークアーキテクチャ設計](../architecture/network-topology.md)
- [VPS フェイルオーバー手順](../operations/vps-failover.md)
- [シークレット & 鍵ライフサイクル管理](../operations/secret-management.md)
- [Nebula モジュール実装](../../nixos/networking/nebula.nix)
- [NAT Loopback 対策モジュール](../../nixos/networking/local-network.nix)
- [タワーサーバー セキュリティ設定](../../nixos/profiles/tower-server/security.nix)
