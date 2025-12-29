# NixOS on Orange Pi Zero3 (torii-chan)

このリポジトリは、Orange Pi Zero3 (コードネーム: `torii-chan`) 向けのNixOS設定を含んでいます。
初期セットアップ用のSDカードイメージの作成から、SDカード構成からHDDルート構成への移行、そして稼働中のシステムへのアップデート適用までをサポートします。

## 構成 (Configurations)

`flake.nix` には主に2つの構成が定義されています。

| 構成名 | 目的 | 説明 |
| :--- | :--- | :--- |
| `torii-chan-sd` | **初期セットアップ** | インストーラーとシステムを含む完全なSDカードイメージをビルドします。最初の起動に使用します。 |
| `torii-chan` | **本番運用 / HDD** | 稼働中のシステム向けの本番用設定です。ルートファイルシステム `/` を外付けHDD (USB-SATA) から、`/boot` をSDカードからマウントするように構成されています。 |

## 必要要件

- **Nix**: Flakesが有効になっていること (`experimental-features = nix-command flakes`)。
- **Orange Pi Zero3**: (1GB/1.5GB/2GB/4GB RAMモデル)。
- **microSD Card**: (16GB以上推奨)。
- **USB-SATA アダプタ & HDD/SSD**: (本番ストレージ用)。

---

## 🚀 セットアップガイド

### Phase 0: 管理用PCのセットアップ (WireGuard)

**重要:** 本番環境では、SSHアクセスはWireGuard VPN経由のみに制限されます。管理用PCをWireGuardピアとして設定する必要があります。

1.  **鍵の生成:**
    ```bash
    wg genkey | tee client_private.key | wg pubkey > client_public.key
    ```
2.  **サーバー設定への追加:**
    `client_public.key` の内容を `hosts/torii-chan/services/wireguard.nix` に追加します（初期設定では実施済み）。
3.  **クライアント設定:**
    `/etc/wireguard/torii-chan.conf` を作成します:
    ```ini
    [Interface]
    PrivateKey = <あなたの秘密鍵>
    Address = 10.0.0.2/32

    [Peer]
    PublicKey = <SOPSから取得したサーバー公開鍵>
    Endpoint = torii-chan.t3u.uk:51820
    AllowedIPs = 10.0.0.0/24
    PersistentKeepalive = 25
    ```

### Phase 1: SDイメージのビルドと書き込み

1.  **SDイメージのビルド:**
    ```bash
    nix build .#nixosConfigurations.torii-chan-sd.config.system.build.sdImage
    ```
    出力ファイルは `result/sd-image/nixos-image-sd-card-....img` に生成されます。

2.  **SDカードへの書き込み:**
    `/dev/sdX` を実際のSDカードデバイス名に置き換えてください。
    ```bash
    sudo dd if=result/sd-image/nixos-image-sd-card-*.img of=/dev/sdX bs=4M status=progress conv=fsync
    ```

3.  **起動とネットワーク:**
    - SDカードを挿入し、電源を入れます。
    - システムは固定IP `192.168.0.128` で構成されています (`hosts/torii-chan/configuration.nix` を参照)。
    - SSHはポート `22` で有効になっています。

4.  **秘密鍵 (Secret Key) のインストール:**
    - **注意:** 初回SD起動時のみ、`sudo` は **パスワードなし** で実行できるように設定されています。これは、パスワードハッシュを復号するための鍵をセットアップする前にロックアウトされるのを防ぐためです。
    - `sops-nix` を使用しているため、復号キーを手動でデバイスに配置する必要があります。
    - ディレクトリとファイルを作成します:
      ```bash
      # Orange Pi 上で実行 (sudoはパスワードを聞いてきません)
      sudo mkdir -p /var/lib/sops-nix
      sudo vi /var/lib/sops-nix/key.txt
      ```
    - あなたの age 秘密鍵を `key.txt` に貼り付け、権限を設定します:
      ```bash
      sudo chmod 600 /var/lib/sops-nix/key.txt
      ```
    - **デプロイ後:** 本番構成（Phase 2）を適用すると、`sudo` はパスワードを要求するようになります。

### Phase 1.5: SDカード上での設定更新（オプション）

HDDに移行する前に、WireGuard設定の反映やパッケージ追加などを行いたい場合は、`torii-chan-sd-live` 構成を使用してください。

**注意:** 初回のデプロイを容易にするため、初期SDイメージではSSHでのrootログインが許可されています。署名検証エラーを回避するため、`root@...` を使用してください。

```bash
nix run nixpkgs#nixos-rebuild -- switch --flake .#torii-chan-sd-live --target-host root@192.168.0.128
```

### Phase 2: HDDへの移行 (Root on HDD)

SDカードの寿命を延ばすため、ルートファイルシステムをHDDに移動します。

1.  **HDDの準備:**
    - USB HDDをOrange Piに接続します。
    - ext4パーティションを作成し、ラベル `NIXOS_HDD` を設定します。
      ```bash
      # 例 (注意して実行してください):
      sudo mkfs.ext4 -L NIXOS_HDD /dev/sda1
      ```

2.  **システムのコピー:**
    - HDDをマウントし、現在のルートファイルシステムをコピーします。
      ```bash
      sudo mount /dev/disk/by-label/NIXOS_HDD /mnt
      sudo rsync -axHAWXS --numeric-ids --info=progress2 / /mnt/
      ```
      *(注: `rsync -x` オプションにより、/proc, /sys, /dev などの疑似ファイルシステムは除外されます。基本的に `/nix`, `/etc`, `/var`, `/home`, `/root` がコピーされていれば十分です)*

3.  **HDD構成のデプロイ:**
    - データがHDDにコピーされたので、それを使用するように設定を切り替えます。
    - **開発用マシン** から以下のコマンドを実行します:
      ```bash
      nixos-rebuild switch --flake .#torii-chan --target-host t3u@192.168.0.128 --use-remote-sudo
      ```
    - これにより `hosts/torii-chan/fs-hdd.nix` の設定が適用され、`NIXOS_HDD` が `/` として、SDカードパーティションが `/boot` としてマウントされます。

4.  **再起動:**
    ```bash
    ssh t3u@192.168.0.128 "sudo reboot"
    ```
    - システムはHDDをルートとして再起動します。

---

## 🔐 セキュリティとアクセス制御

### SSHアクセス
- **ポート:** `22` (標準)
- **初期セットアップ (SD Image):** 全インターフェースで許可されています。
- **本番運用 (HDD Config):** **WireGuard VPN インターフェース (`wg0`) からのみ** に制限されます。
  - **警告:** 本番構成 (`torii-chan`) をデプロイする前に、必ず `hosts/torii-chan/services/wireguard.nix` にあなたの WireGuard Peer 設定を追加してください。
  - VPN接続が確立できない状態でデプロイすると、SSHに接続できなくなりロックアウトされます。

## 🔐 秘密情報管理 (SOPS)

- **編集:**
  ```bash
  nix shell nixpkgs#sops -c sops secrets/secrets.yaml
  ```
- **公開鍵の場所:** `secrets/.sops.yaml` で定義されています。
- **実機での設定:** 秘密鍵を `/var/lib/sops-nix/key.txt` に配置する必要があります。
- **トラブルシューティング:**
  - パスワードハッシュが `/etc/shadow` に反映されない場合は、`users.mutableUsers = false` が設定されているか確認してください。
  - `/run/secrets/` や `/run/secrets-for-users/` に復号されたファイルがあるか確認してください。
  - `journalctl -t nixos-activation-script` でアクティベーション時のログを確認できます。

## 🛠 トラブルシューティング

- **U-Boot / BL31 の問題:** このFlakeは `binman` の要件を満たすために、Overlayを使って `BL31` ファームウェアをU-Bootビルドプロセスに注入しています。ビルドに失敗する場合は `flake.nix` のOverlaysを確認してください。
- **SSHアクセス:** ポートは `22` です。本番モードでのアクセス制限に注意してください。

---

## ⚠️ 重要: 本番構成をデプロイする前に (CRITICAL)

システムからのロックアウト（本番環境ではLAN内からのSSHがブロックされるため）を防ぐために、以下の手順を必ず確認してください。

1.  **WireGuard Peer の追加:**
    `hosts/torii-chan/services/wireguard.nix` を編集し、クライアントの公開鍵を追加してください。
    ```nix
    peers = [
      {
        publicKey = "あなたのクライアント公開鍵";
        allowedIPs = [ "10.0.0.2/32" ];
      }
    ];
    ```
    *これを行わないとVPNに接続できず、結果としてSSHにアクセスできなくなります。*

2.  **Secrets の確認:**
    `secrets/secrets.yaml` に以下が含まれていることを確認してください:
    - `cloudflare_api_env` (DDNS用)
    - `torii_chan_wireguard_private_key` (サーバー用)

3.  **HDD の準備:**
    HDDがラベル `NIXOS_HDD` でフォーマットされ、SDカードからデータがコピーされていることを確認してください。
