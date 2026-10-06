# Orange Pi Zero3 (Allwinner H618) ハードウェア・SBC ガイド

本ドキュメントは，Allwinner H618 SoC を搭載したシングルボードコンピュータ（SBC）である Orange Pi Zero3（ホスト名: `torii-chan`）における，U-Boot ブートチェーン，SD / HDD 分離ストレージ構成，インストーライメージビルド，および 1 GB RAM 環境下でのリソース制約回避に関する技術仕様をまとめたものである．

---

## 1. ハードウェア仕様とクラスタ内での役割

### 基本諸元

| 項目 | 諸元・仕様 |
| :--- | :--- |
| **対象ホスト** | `torii-chan`（SBC モード） |
| **SoC** | Allwinner H618（Quad-core ARM Cortex-A53 @ 1.5 GHz） |
| **GPU** | ARM Mali-G31 MP2（OpenGL ES 3.2，Vulkan 1.1） |
| **RAM** | 1 GB LPDDR4（オンボード） |
| **有線 LAN** | ギガビット Ethernet（`end0`，Realtek RTL8211F PHY） |
| **ストレージ** | microSD スロット（ブート用）+ USB 2.0 接続 2.5インチ SATA HDD（ルート用） |
| **電源** | USB Type-C（5V / 3A 推奨） |

### クラスタ内での役割

- **Nebula Gateway / Lighthouse**: メッシュネットワーク `10.0.0.0/24` の固定灯台ノード（`10.0.0.1:4242`）およびリレーとして常時稼働．
- **ポートフォワーディング**: 外部からの Minecraft 接続（TCP 25565）を受け，家庭内 LAN 上の `shosoin-tan`（`10.0.0.4`）へ NAT 転送．
- **Cloudflare DDNS**: グローバル IP アドレスの変化を検知し，`torii-chan.t3u.uk` および `*.mc.t3u.uk` の A レコードを自動更新．
- **VPS フェイルオーバー設計**: SBC のハードウェア障害時は，同一のホスト名と暗号化シークレットを共有する ConoHa VPS（`torii-chan-vps`）へシームレスに役割を移譲可能（詳細は [`docs/operations/vps-failover.md`](../operations/vps-failover.md) を参照）．

---

## 2. ブートチェーンと SD / HDD 分離ストレージ構成

### Allwinner H618 ブートシーケンスと U-Boot

Allwinner 製 SoC は，起動時に BROM（内蔵 Mask ROM）が SD カードの特定セクタから U-Boot SPL を読み込むアーキテクチャを持つ．

```text
[BROM]
  ↓ (SD カード先頭 8 KiB オフセットから読込)
[U-Boot SPL (u-boot-sunxi-with-spl.bin)]
  ↓
[U-Boot 本隊]
  ↓ (SD カード /boot/extlinux/extlinux.conf 読込)
[Linux Kernel & initrd]
  ↓ (rootdelay 待機 & USB-SATA ブリッジ認識)
[ルートファイルシステム (USB HDD: /dev/disk/by-label/NIXOS_HDD)]
```

#### U-Boot の注入 (`hosts/torii-chan/sd-installer.nix`)

SD カードイメージ生成時に，Flake オーバーレイでビルドされた `ubootOrangePiZero3` の SPL バイナリをオフセット 8 KiB（ブロックサイズ 1024，seek 8）の位置へ直接書き込む．

```nix
sdImage.postBuildCommands = ''
  echo "Writing U-Boot to image..."
  dd if=${pkgs.ubootOrangePiZero3}/u-boot-sunxi-with-spl.bin of=$img bs=1024 seek=8 conv=notrunc
'';
```

#### extlinux ブートローダの採用 (`hosts/torii-chan/sbc.nix`)

UEFI や GRUB は使用せず，U-Boot の標準仕様に準拠した extlinux 互換ローダを使用する．

```nix
boot.loader = {
  generic-extlinux-compatible.enable = true;
  grub.enable = false;
};
```

これにより，`/boot/extlinux/extlinux.conf` に NixOS の世代別ブートエントリが自動生成され，カーネル更新や世代ロールバックが可能となる．

### SD / HDD 分離アーキテクチャ

SD カードはランダム書き込み耐性が低く，24時間稼働のルータ・ゲートウェイ用途でログや Nix store 更新を行うとフラッシュメモリの早期摩耗死（クラッシュ）を招く．そのため，**ブート部とルートファイルシステムを物理的に分離** している．

| 領域 | デバイス | ラベル / マウント先 | ファイルシステム | 定義モジュール |
| :--- | :--- | :--- | :--- | :--- |
| **ブート** | microSD カード | `NIXOS_SD` (`/boot`) | `ext4` | [`hosts/torii-chan/fs-hdd.nix`](../../hosts/torii-chan/fs-hdd.nix) |
| **ルート** | 外付け USB HDD | `NIXOS_HDD` (`/`) | `ext4` (`noatime`) | [`hosts/torii-chan/fs-hdd.nix`](../../hosts/torii-chan/fs-hdd.nix) |

#### USB HDD の安定化とハードウェア quirk

USB 接続された 2.5 インチ HDD をルートドライブとして安定動作させるため，以下の対策を適用している．

1. **UAS (USB Attached SCSI) の無効化**:
   本機で使用している JMicron JMS583 USB-SATA ブリッジ（`152d:0583`）は UAS 動作時にタイムアウトや I/O エラーを起こしやすい．カーネルパラメータ `usb-storage.quirks=152d:0583:u` を指定して UAS を無効化し，クラシカルな USB Mass Storage ドライバで駆動させている．
2. **ルートドライブ認識待ちの延長 (`rootdelay=10`)**:
   USB デバイスはバスのリセットおよびスピンアップに時間を要するため，`rootdelay=10` を付与して initrd 内でのマウントタイムアウトを回避している．
3. **過剰なヘッド退避の抑止 (`hdd-apm.service`)**:
   WD Scorpio Blue などの 2.5 インチ HDD は，初期の APM（Advanced Power Management）設定によりアイドル数十秒でヘッドを退避し，`Load_Cycle_Count` が急増して短寿命化する．`hdparm -B 255 /dev/disk/by-label/NIXOS_HDD` を systemd サービスで実行し，APM によるスピンダウンを完全に無効化している．
4. **SMART 監視のピンポイント指定 (`smartd`)**:
   USB ブリッジ越しの自動プローブは異常動作を招く恐れがあるため，`autodetect = false` とした上で `-d sat` オプションを指定し，明示的に監視対象を定義している．

---

## 3. SD カードインストーライメージと初期プロビジョニング

### イメージ生成手順 (`hosts/torii-chan/build-sd-image.sh`)

新規セットアップ時は，スクリプトを用いてインストーラ SD イメージを作成する．

```bash
./hosts/torii-chan/build-sd-image.sh
```

#### スクリプトの動作機構

1. ランダムな一時パスワード（16進数 16文字）を自動生成し，平文を `result-sd-temp-password.txt`（パーミッション `0600`）に出力する．
2. `openssl passwd -6` で SHA-512 crypt ハッシュを算出する．
3. 環境変数 `TORII_INSTALLER_TEMP_PASSWORD_HASH` を介して `--impure` ビルドを実行し，インストーラ構成（[`hosts/torii-chan/sd-installer.nix`](../../hosts/torii-chan/sd-installer.nix)）へハッシュを注入する．
4. ビルド成果物（`result-sd-image/sd-image/*.img`）は `compressImage = false`（非圧縮）となっており，高速に SD カードへ書き込める．

### aarch64 ネイティブビルド環境

インストーライメージはクロスコンパイルではなく，**aarch64 ネイティブビルド** として構成されている．x86_64 ホスト（`BrokenPC` 等）でビルドする場合，`nixos/base/nix.nix` で設定された QEMU binfmt エミュレーション（`boot.binfmt.emulatedSystems = [ "aarch64-linux" ]`）を通じて透過的に実行される．

### 初期導入・HDD 移行手順

1. **SD カードへの書き込み**:
   ```bash
   sudo dd if=result-sd-image/sd-image/nixos-image-sd-card-*.img of=/dev/sdX bs=4M status=progress conv=fsync
   ```
2. **インストーラ起動と SSH 接続**:
   Orange Pi Zero3 に SD を挿入して起動．静的 LAN IP（`192.168.0.128`）が割り当てられるため，`result-sd-temp-password.txt` の一時パスワードで SSH ログインする．
3. **SSH ホスト鍵から age 鍵を導出**:
   ```bash
   ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub
   ```
   得られた公開鍵をリポジトリの `.sops.yaml`（`&torii_chan`）へ登録し，`sops updatekeys secrets/hosts/torii-chan.yaml` を実行してコミットする．
4. **本番 SD 構成への切り替え**:
   ```bash
   nixos-rebuild switch --flake .#torii-chan-sd --target-host root@192.168.0.128
   ```
5. **HDD へのルート複製と移行**:
   外付け HDD（`/dev/sda`）をフォーマットし，稼働中の SD カードルートを rsync で同期する:
   ```bash
   sudo mkfs.ext4 -L NIXOS_HDD /dev/sda1
   sudo mkdir -p /mnt/hdd
   sudo mount /dev/sda1 /mnt/hdd
   sudo rsync -aAXHx --exclude='/proc/*' --exclude='/sys/*' --exclude='/dev/*' \
     --exclude='/run/*' --exclude='/tmp/*' --exclude='/mnt/*' --exclude='/lost+found' \
     --exclude='/boot/*' --exclude='/swapfile' / /mnt/hdd/
   sudo sync
   ```
6. **本番 HDD 構成の適用と再起動**:
   ```bash
   nixos-rebuild switch --flake .#torii-chan-hdd --target-host t3u@10.0.0.1 --sudo --ask-sudo-password
   sudo reboot
   ```

---

## 4. 低スペック制約 (1 GB RAM) とカーネル制約への対応

Orange Pi Zero3 はメモリ容量が 1 GB と極めて少なく，カーネル機能にも一部制限があるため，[`nixos/profiles/sbc/default.nix`](../../nixos/profiles/sbc/default.nix) にて以下の制約回避策を講じている．

### サンドボックスと seccomp BPF の無効化

Allwinner 向け Linux カーネルでは，`user_namespaces` や `seccomp BPF` のサポートが不完全である．この状態で Nix の標準ビルドを実行すると，サンドボックス環境の作成やシステムコールフィルタでエラーが発生する．

```nix
# nixos/profiles/sbc/default.nix
nix.settings = {
  sandbox = false;
  filter-syscalls = false;
};
```

リモートデプロイ時にも，ターゲット実機上でのビルドエラーを防ぐため，同様のフラグを付与してコマンドを実行する:

```bash
nixos-rebuild switch --flake .#torii-chan-hdd \
  --target-host t3u@10.0.0.1 \
  --sudo --ask-sudo-password \
  --option sandbox false --option filter-syscalls false
```

### スワップファイルの必須化とメモリ枯渇 (OOM) 対策

1 GB の物理メモリでは，Nix のプロファイル評価やカーネルモジュール展開，複数プロセスの同時稼働によって容易に OOM Killer が発動する．

- **4 GB スワップファイルの確保**:
  ```nix
  # nixos/profiles/sbc/default.nix
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 4096;
    }
  ];
  ```
- **swappiness の引き下げ (`vm.swappiness = 10`)**:
  極小メモリ環境ではあるものの，SD カードや USB HDD への過剰なスワップ I/O はシステム全体を著しくフリーズ（スラッシング）させる．そのため `swappiness` を `10` に設定し，極力物理 RAM を使い切るまでディスクスワップへの書き出しを遅延させている．

---

## 関連ドキュメント

- [ホスト概要: `hosts/torii-chan/README.md`](../../hosts/torii-chan/README.md)
- [SBC プラットフォーム定義: `hosts/torii-chan/sbc.nix`](../../hosts/torii-chan/sbc.nix)
- [HDD ルートファイルシステム定義: `hosts/torii-chan/fs-hdd.nix`](../../hosts/torii-chan/fs-hdd.nix)
- [SD ルートファイルシステム定義: `hosts/torii-chan/fs-sd.nix`](../../hosts/torii-chan/fs-sd.nix)
- [SD インストーラ定義: `hosts/torii-chan/sd-installer.nix`](../../hosts/torii-chan/sd-installer.nix)
- [SBC 共通プロファイル: `nixos/profiles/sbc/default.nix`](../../nixos/profiles/sbc/default.nix)
- [VPS フェイルオーバー運用手順: `docs/operations/vps-failover.md`](../operations/vps-failover.md)
