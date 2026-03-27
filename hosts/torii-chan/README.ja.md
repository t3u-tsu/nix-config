# ホスト名: torii-chan (Orange Pi Zero3)

このディレクトリには、WireGuardサーバーおよびDDNSクライアントとして使用される `torii-chan` (Orange Pi Zero3) のNixOS設定が含まれています。

## ハードウェア仕様
- **モデル:** Orange Pi Zero3 (Allwinner H618)
- **アーキテクチャ:** aarch64-linux

## Flake内の構成
- `torii-chan-sd`: 初期セットアップ用SDイメージのビルド。
- `torii-chan-sd-live`: SDカード運用での設定更新。
- `torii-chan`: HDDルート運用向けの本番構成。

---

## 🚀 セットアップガイド

### Phase 1: SDイメージのビルドと書き込み
1. **ビルド:**
   ```bash
   nix build .#nixosConfigurations.torii-chan-sd.config.system.build.sdImage
   ```
2. **書き込み:**
   ```bash
   sudo dd if=result/sd-image/nixos-image-sd-card-*.img of=/dev/sdX bs=4M status=progress conv=fsync
   ```

### Phase 2: 初期プロビジョニング
1. **鍵の配置:** age秘密鍵を `/var/lib/sops-nix/key.txt` に配置します。
2. **初回デプロイ:**
   ```bash
   nix run nixpkgs#nixos-rebuild -- switch --flake .#torii-chan-sd-live --target-host root@192.168.0.128
   ```

### Phase 3: HDD移行 (完了 ✅)
1. **HDD準備:** ラベル `NIXOS_HDD` でフォーマットします。
2. **データコピー:** `/` をHDDパーティションにrsyncします。
3. **構成切り替え:**
   ```bash
   nix run nixpkgs#nixos-rebuild -- switch --flake .#torii-chan --target-host t3u@10.0.0.1 --sudo
   ```   *現在はHDDをルートとして、SDカードを/bootとして運用されています。*

## 🔐 サービスと秘密情報
- **Update Hub:** ネットワーク全体の更新状態を管理する Coordinated Update Hub。10.0.1.1:8080 でステータスを提供します。
- **WireGuard:** 管理用VPNサーバー (10.0.0.1)。
- **SSH アクセス制限:** セキュリティ強化のため、SSHアクセスは WireGuard (`wg0`) インターフェース経由のみに制限されています。
- **DDNS:** Cloudflare DDNS (favonia)。APIトークンが必要です。`torii-chan.t3u.uk` に加え、Minecraft用の `mc.t3u.uk` および `*.mc.t3u.uk` も管理しています。
- **秘密情報:** `sops-nix` で管理。 `sops secrets/secrets.yaml` で編集。

## 🌐 ネットワークと接続
管理用PCからのアクセス：
```bash
ssh t3u@10.0.0.1
```

## 🛠️ 運用・トラブルシューティング

### リモートデプロイ時のビルドエラー (seccomp / sandbox)
Orange Pi などのカスタマイズ済み（またはレガシー）カーネルは、Nix デーモンが要求する特定の Linux カーネルセキュリティ機能 (`user_namespaces`, `seccomp BPF`) をサポートしていないことがあります。
このため、通常のリモートデプロイを実行すると `error: unable to load seccomp BPF program` などの出力でビルドが強制終了、あるいはサイレントにフリーズします。
この制限を回避し、リモート先（torii-chan自身）で設定評価・適用を完遂するには、以下のオプション構文を使用してください（※ `sudo nixos-rebuild` として実行すると SSH 鍵転送に失敗するため、一般ユーザーから実行します）：

```bash
nixos-rebuild switch --flake .#torii-chan --target-host t3u@10.0.0.1 --use-remote-sudo --ask-sudo-password --option sandbox false --option filter-syscalls false
```
※ `configuration.nix` 内にも `nix.settings.sandbox = false;` 等を記述していますが、手動稼働時はオプションフラグの付与が最も確実です。

### SSH 接続が不安定またはタイムアウトする場合
Orange Pi のリソース制限により、鍵交換でタイムアウトすることがあります。接続時は `KexAlgorithms` を明示的に指定するか、設定で `curve25519-sha256` が強制されていることを確認してください。

```bash
# 手動接続時の例
ssh -o KexAlgorithms=curve25519-sha256 t3u@10.0.0.1
```

### ネットワーク（WireGuard）の安定化
楽天モバイルなど、親回線の MTU が低い環境 (1340等) では、パケットの断片化により通信が固まることがあります。`wg0` / `wg1` の MTU はマージンを取って `1300` に設定されています。

### メモリ不足（OOM）対策
ビルド時にメモリが不足し、`nixos-rebuild` が `Result: oom-kill` で失敗することがあります。
`/var/lib/swapfile` (4GB) を常設しており、`vm.swappiness = 10` で最適化されています。

### USB HDD の安定化 (UAS 相性問題の回避)
JMicron JMS583 ブリッジ (`152d:0583`) における UAS (USB Attached SCSI) の相性問題を回避するため、カーネル引数 `usb-storage.quirks=152d:0583:u` を適用し、UAS を無効化して安定した `usb-storage` ドライバを使用するように構成しています。

### ファイアウォールログの抑制
インターネットに露出しているため、外部からのスキャン等のパケット拒否ログが `dmesg` を埋め尽くすのを防ぐため、`logRefusedConnections = false` を設定しています。

### 自動更新 (Update Hub) の同期不全
Hub から通知されたコミットがローカルの `git` で見つからない場合、以下のコマンドでリポジトリを手動同期してください。
```bash
cd ~/nix-config
git fetch --all
git reset --hard origin/main
```
同期後、Webhook ポートを叩くことで即時更新を再試行できます。
```bash
curl -X POST http://127.0.0.1:8081/trigger-update
```
