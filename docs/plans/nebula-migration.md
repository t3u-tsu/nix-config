# Nebula メッシュVPN 移行計画（要点）

> **2026-08-10 更新**: オーバーレイサブネットを **10.0.0.0/24** に変更（旧 `10.0.2.0/24`）。
> WireGuard 管理網（`wg0`, `10.0.0.0/24`）と同じ帯域に統一し、`home/programs/ssh.nix` の
> ホスト定義（`10.0.0.1`〜`10.0.0.100`）と整合させるため。CA 再発行 + 全ノード証明書再署名を
> `scripts/nebula-rotate-ca.sh` で実施済み。

WireGuard（Hub-and-Spoke）→ Nebula（フルメッシュ）への移行。
**単一オーバーレイ統合案**: wg0/wg1 を 1 つの Nebula 網に統合し、ゾーン分離は証明書グループ + Nebula ファイアウォールで行う。

## ネットワーク設計

- ネットワーク名 `nebula0`、サブネット **10.0.0.0/24**、UDP **4242**（Lighthouse/Relay のみ固定）
- **MTU は全ノード共通の単一値**（P2P メッシュでは送信側の tun MTU がそのままパケットサイズになるため、
  最小の拠点に全員が合わせる。詳細は下記「MTU」節）
- 各ノードは Lighthouse（torii-chan）に報告 → P2P 接続。中央死後も確立済みトンネルは継続

| ノード | Nebula IP | グループ | 役割 |
| :--- | :--- | :--- | :--- |
| torii-chan | 10.0.0.1 | mgmt | **Lighthouse + Relay**（SBC/VPS 共有） |
| sando-kun | 10.0.0.2 | mgmt | クライアント |
| kagutsuchi-sama | 10.0.0.3 | mgmt | クライアント（restic 受信） |
| shosoin-tan | 10.0.0.4 | mgmt, app | クライアント（Minecraft） |
| BrokenPC | 10.0.0.100 | mgmt, app | クライアント（＝持ち出しPC） |

- **mgmt** = 全ノード（SSH 等の管理用）、**app** = Minecraft 等のアプリ通信ノード
- フェイルオーバー: VPS は同一証明書・鍵を共有。`advertise_addrs = ["torii-chan.t3u.uk:4242"]` + DDNS 差替で全ピア無変更で追随

### MTU（全ノード共通）

- **共通 MTU: 1320（✅ Phase 2 実測確定 2026-08-11: BrokenPC@楽天モバイル → torii-chan で `ping -M do -s 1292` 成功）**
  - ルート mtu 属性は `ip link set` に追従しない（`cache mtu` が旧値のまま残り EMSGSIZE）。実測時は
    `ip route replace 10.0.0.0/24 dev nebula0 src 10.0.0.100 mtu <value>` でルートを書換える。
    switch 適用で Nebula が tun を再作成すればルートも新 MTU で生成されるため、通常は不要。
- 計算: `共通 MTU = 最小パス MTU (1380) − Nebula オーバーヘッド (60) = 1320`
  - Nebula ヘッダ 16B（`header/header.go` の `Len = 16`）+ AEAD タグ 16B + UDP 8B + IPv4 20B
  - 最小パス MTU 1380 は楽天モバイル回線の実測値（`tracepath 1.1.1.1` の pmtu。
    **IPv4 パケット全体基準であり、NAT64 変換の影響はこの値に既に含まれる**）

## CA・鍵管理

- **CA 秘密鍵**: BrokenPC のローカル領域のみ（`~/.nebula-ca/`、`-encrypt` でパスフレーズ保護）。リポジトリ外・SOPS に載せない
- **CA 証明書** (`ca.crt`): `secrets/common.yaml`
- **ノード証明書・秘密鍵**: `secrets/hosts/<host>.yaml`（各ホスト + master 鍵）
- 発行: `nebula-cert ca -name t3u-home-ca -networks 10.0.0.0/24 -groups mgmt,app -encrypt` →
  `nebula-cert sign -name <host> -networks <ip>/24 -groups <g> -duration 8760h`
- 有効期限 1 年。失効は `pki.blocklist`（全ホストの設定に列挙。自動配布されない）

## ファイアウォール

**2 レイヤ構成**（`networking.firewall` は全ホストでデフォルト有効の OS レベルファイアウォール。ゲートウェイ専用ではない）:

- **NixOS firewall** = 物理 WAN/LAN の受信制御
- **Nebula firewall** = nebula0 トンネル内の制御
- nebula0 は `networking.firewall.trustedInterfaces` に追加し、トンネル内は Nebula ファイアウォールに一本化

**方針: ポートは「サービスをデプロイしたホスト」で開ける。** 共通モジュールは ICMP のみ、後は `extraInbound` で追加。

| ホスト | Nebula inbound（追加分） | 理由 |
| :--- | :--- | :--- |
| torii-chan | 22 (mgmt), 25565 (app) | SSH / Minecraft DNAT 戻り |
| shosoin-tan | 22 (mgmt), 25565 (app, cidr 10.0.0.1) | SSH / Minecraft 受信 |
| kagutsuchi-sama | 22 (mgmt) | SSH / restic SFTP |
| sando-kun | 22 (mgmt) | SSH |
| BrokenPC | （なし = ICMP のみ） | サービスなし |

- 全ノード共通: inbound ICMP、outbound any
- 共通 outbound any / 相手側 inbound で受入制御（現行 wg1 全許可 → サービス単位の開放へ厳密化）

**WAN 側（torii-chan の NixOS firewall）**:
- UDP 4242（Nebula、`services.nebula` が自動追加）
- TCP 25565（Minecraft 公開、rate-limit 継続）。DNAT 転送先を `10.0.1.4 → 10.0.0.4` に変更（MASQUERADE 含む）

## Relay の位置づけ

- **目的**: ホールパンチングが失敗する環境（UDP は通るが P2P が成立しない NAT 等）でのフォールバック
- **実測による重要事例**: 楽天モバイル（NAT64）は UDP は通るがステートフル NAT のため
  直接 P2P が成立しにくい → **モバイル時は Relay 経由が主経路になる**（Lighthouse への
  接続自体は外向きで問題なし）。Relay はモバイル参加の要となる
- 全ノードが `relays = ["10.0.0.1"]` を指定し、直接接続失敗時に torii-chan 経由でフォールバック

## 実装の骨子

- 共通モジュール `nixos/networking/nebula.nix`（新規）: `services.nebula.networks.nebula0` をホスト差分
  （isLighthouse/isRelay/IP/groups/**mtu**/extraInbound）で生成。SOPS 参照 + `trustedInterfaces = ["nebula0"]` を内包
- `tower-server/security.nix`: wg0 参照を撤去し `extraInbound = [{port=22; proto="tcp"; group="mgmt";}]`
- `nixos/services/minecraft/default.nix`: `extraInbound` に 25565 を追加
- `nixos/profiles/gateway/default.nix`: NAT 転送先を 10.0.0.4 へ、`extraInbound` に 25565 を追加

## 移行フェーズ

1. **Phase 1 並行導入**: CA 作成 → 証明書発行 → SOPS 格納 → 全ホストに nebula0 追加（WireGuard 維持）→ flake check / dry-activate → 適用（承認後）
2. **Phase 2 検証**: P2P 疎通 / SSH 切替 / Minecraft メッシュ内 / グループ制御 / **DNAT 戻り（conntrack 相互作用）** / restic SFTP / Lighthouse 停止テスト / Relay フォールバック / **MTU 1320 ✅（2026-08-11 楽天モバイルで実測済み）** / **モバイル時（NAT64）の P2P 可否と Relay 経由確認**
3. **Phase 3 全面移行**: アプリ切替 → NAT 転送先変更 → SSH 経路切替 → wg0/wg1 撤去（`wireguard.nix` 削除、51820/51821 閉鎖）
4. **Phase 4 運用**: 証明書ローテーション（1 年）、blocklist 更新、第二 Lighthouse は将来検討

## 主要リスク

- CA 鍵漏えい = 網全体 → BrokenPC ローカルのみ・パスフレーズ保護
- DNAT 転送と Nebula conntrack の不整合 → inbound に 25565 を明示許可 + Phase 2 で実機確認
- モバイル時は NAT64 の性質上 P2P が成立せず Relay に依存 → Relay（torii-chan）の可用性が重要。
  万一 torii-chan が落ちているときのモバイル時アクセス手段（現行 wg0 は並行維持でカバー）
- MTU 1320 は境界値（パス MTU 1380 ちょうど）→ 2026-08-11 楽天モバイルで通過確認済み。経路変動で不安定が観測されたら 1300 に下げる
