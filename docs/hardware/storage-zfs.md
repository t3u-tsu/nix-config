# レガシー BIOS ブート & ZFS ストレージ運用ガイド

本ドキュメントは，レガシー BIOS（MBR）環境で稼働するタワー型サーバ群（`shosoin-tan`，`sando-kun`）のブート設計，および `shosoin-tan` における ZFS Mirror プール（`tank-1tb`）の構築，定期スクラブ，障害検知，ディスク交換・リビルド（`zpool replace`）手順をまとめたものである．

---

## 1. レガシー BIOS (MBR) ホストのブート設計

### ハードウェア背景

| ホスト名 | CPU | RAM | システムドライブ | ブート方式 | 主な役割 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`shosoin-tan`** | Intel Core i7-870（Nehalem / 4C8T） | 16 GB | 480 GB SATA SSD | Legacy BIOS (MBR) | Minecraft サーバ，ZFS ストレージ |
| **`sando-kun`** | Intel Core i7-860（Nehalem / 4C8T） | 8 GB | 250 GB SATA HDD | Legacy BIOS (MBR) | 汎用タワーサーバ，検証環境 |

両機は第1世代 Intel Core プロセッサ時代のマザーボードを搭載しており，UEFI ブートに非対応（またはファームウェアの挙動が不安定）であるため，**クラシカルな Legacy BIOS（MBR パーティションテーブル）による起動** を採用している．

### GRUB ブートローダ設定

[`hosts/shosoin-tan/default.nix`](../../hosts/shosoin-tan/default.nix) および [`hosts/sando-kun/default.nix`](../../hosts/sando-kun/default.nix) におけるブートローダ設定は以下の通りである．

```nix
# hosts/shosoin-tan/default.nix
boot.loader.grub = {
  enable = true;
  efiSupport = false;
  device = "/dev/disk/by-id/ata-CT480BX500SSD1_1946E3D7A95A";
};

# hosts/sando-kun/default.nix
boot.loader.grub = {
  enable = true;
  efiSupport = false;
  device = "/dev/disk/by-id/ata-ST9250320AS_5SW1VK4F";
};
```

#### 設計の要点

1. **`efiSupport = false`**:
   UEFI 用の ESP（EFI システムパーティション）へのブートローダ配置を無効化し，ディスクの先頭 512 バイト（MBR ブートセクタ）に GRUB ステージ 1 を直接書き込む．
2. **`device` の永続的 ID 指定**:
   `/dev/sda` のような動的デバイス名ではなく，シリアル番号を含む `/dev/disk/by-id/...` を指定する．これにより，SATA ケーブルの挿し替えや複数ディスクの認識順序変動による「ブートセクタ書き込み先の誤認」および「起動不能」を防止する．

### MBR パーティションレイアウト

初期プロビジョニング時，ディスクは `parted` により `msdos`（MBR）ラベルで初期化される．

- **第1パーティション (`part1`)**: `linux-swap`（8 GiB）— メモリ枯渇防止（初期インストール時に swapon）．
- **第2パーティション (`part2`)**: `fat32`（500 MiB，boot フラグ有効）— `/boot` にマウント．
- **第3パーティション (`part3`)**: `ext4`（残り全域）— ルート `/` にマウント．

### ZFS 必須要件: `networking.hostId`

NixOS で ZFS サポートを有効化する場合，意図しないホストによるプールの多重インポート・データ破壊を防ぐため，**32 ビットの 16 進数ホスト ID** の定義が必須である（未定義の場合は評価時にアサーションエラーとなる）．

- `shosoin-tan`: `networking.hostId = "8425e349";`
- `sando-kun`: `networking.hostId = "5a4d0001";`

---

## 2. ZFS Mirror プール構成 (shosoin-tan: `tank-1tb`)

`shosoin-tan` には，2 台の 1 TB HDD を束ねた RAID-1 相当の ZFS Mirror プール `tank-1tb` が構成されている．

### プール設計諸元

- **プール名**: `tank-1tb`
- **トポロジ**: 2-way Mirror（ミラー構成）
- **構成ドライブ**: 1 TB SATA HDD x 2 台
- **実効容量**: 約 930 GiB（耐障害性: 1 台の完全障害まで耐過可能）
- **マウントポイント**: `/mnt/tank-1tb`
- **主な役割**:
  - Minecraft サーバデータの高信頼性ローカルバックアップ保管庫（`/mnt/tank-1tb/backups/minecraft`）
  - Restic による世代別スナップショット保管
  - 大容量スクラッチデータ領域

### NixOS 宣言と自動マウント

[`hosts/shosoin-tan/default.nix`](../../hosts/shosoin-tan/default.nix) および [`hosts/shosoin-tan/hardware.nix`](../../hosts/shosoin-tan/hardware.nix) にて以下を宣言している．

```nix
# default.nix
boot = {
  supportedFilesystems = [ "zfs" ];
  zfs.forceImportRoot = false;
};

# hardware.nix
boot.zfs.extraPools = [ "tank-1tb" ];
```

- `boot.zfs.extraPools`: 起動時に `tank-1tb` を自動的にインポートする．
- `boot.zfs.forceImportRoot = false`: 26.11 以降の既定値変更に備え，強制インポートを明示的に抑止．

### 初期作成コマンド (参考)

```bash
sudo modprobe zfs
sudo zpool create -m /mnt/tank-1tb tank-1tb mirror /dev/disk/by-id/<DISK1> /dev/disk/by-id/<DISK2>
```

---

## 3. 定期スクラブとデータ整合性検証

ZFS の最大の利点は，全ブロックに対するチェックサム検証により，HDD の磁気劣化やコントローラの誤動作に伴う **サイレントデータ破損（Bit Rot / ビット化け）を自動検知・自己修復** できる点にある．

### 手動スクラブ操作

```bash
# スクラブの開始
sudo zpool scrub tank-1tb

# 進行状況と結果の確認
zpool status tank-1tb

# 必要に応じたスクラブの一時停止・中止
sudo zpool scrub -s tank-1tb
```

### スクラブ出力の読み方

```text
  pool: tank-1tb
 state: ONLINE
  scan: scrub in progress since Tue Oct  6 03:00:00 2026
	128G scanned at 1.20G/s, 64.0G issued at 600M/s, 500G total
	0B repaired, 12.80% done, 00:12:30 to go
config:

	NAME        STATE     READ WRITE CKSUM
	tank-1tb    ONLINE       0     0     0
	  mirror-0  ONLINE       0     0     0
	    sdb     ONLINE       0     0     0
	    sdc     ONLINE       0     0     0

errors: No known data errors
```

- `repaired`: ミラーのもう一方の正常ブロックを用いて自動修復されたデータ量．
- `CKSUM`: チェックサム不整合が検知された回数（非ゼロの場合はドライブの劣化を疑う）．

---

## 4. 障害検知とヘルスモニタリング

### プールステータス診断

日常的な確認やスクリプトによる異常検知には，サマリ表示を活用する．

```bash
zpool status -x
```

- 正常時: `all pools are healthy` と出力される．
- 異常時: 影響を受けているプール名と障害内容が表示される．

#### ステータスの判別

| ステータス | 意味 | 健全度・影響 |
| :--- | :--- | :--- |
| **`ONLINE`** | 全デバイスが正常に稼働している． | 正常 |
| **`DEGRADED`** | ミラー内の 1 台がオフラインまたは故障しているが，残る 1 台で読み書きは継続可能． | **警告**: 冗長性が喪失しており，早期交換が必要 |
| **`FAULTED`** | プール全体が破損またはアクセス不能となり，マウントできない． | **致命的**: データ復旧作業が必要 |
| **`UNAVAIL`** | デバイスファイルが見つからない（物理切断，電源断など）． | **エラー**: 接続またはハードウェア確認が必要 |

### SMART 情報によるハードウェア予兆検知

ZFS エラーカウンタの上昇前に，`smartctl` を用いて物理セクタの劣化を定期的に確認する．

```bash
sudo smartctl -a /dev/disk/by-id/<DISK_ID>
```

以下の属性がゼロより大きくなっている場合は，ディスクの寿命が近づいている:
- `Reallocated_Sector_Ct`（代替処理済のセクタ数）
- `Current_Pending_Sector`（代替処理保留中のセクタ数）
- `Offline_Uncorrectable`（回復不可能セクタ数）

---

## 5. ディスク交換・リビルド手順 (`zpool replace`)

ミラー内の 1 台に障害が発生し，プールが `DEGRADED` 状態となった場合の交換・復旧手順である．

### Step 1: 故障ディスクの特定と物理換装

1. `zpool status tank-1tb` を実行し，エラーが多発しているディスクの識別子（またはシリアル番号）を特定する．
2. システムをシャットダウンし，故障した HDD を新しい HDD へ物理的に交換する．
3. システムを起動し，新しいディスクが認識されていることを確認する:
   ```bash
   lsblk -o NAME,SIZE,SERIAL,MODEL,PATH
   ```
4. `/dev/disk/by-id/` 配下で新しいディスクの永続的デバイスパスを確認する（例: `/dev/disk/by-id/ata-WDC_WD10EZEX-xx_WD-WCC4Nxx`）．

### Step 2: プールへのリプレース指示

`zpool replace` コマンドを実行し，旧ディスクを新ディスクで置き換える．

```bash
sudo zpool replace tank-1tb <旧ディスク識別子> /dev/disk/by-id/<新ディスクID>
```

※旧ディスクがすでに完全故障して切断されている場合，`zpool status` に表示されている数値（GUID）を `<旧ディスク識別子>` として指定する．

### Step 3: リシルバリング (Resilvering) の監視

リプレース指示を発行すると，生き残っている正常ディスクから新ディスクへデータの同期（リシルバリング）が自動的に開始される．

```bash
zpool status tank-1tb
```

進行中は以下のような情報が表示される:
```text
  scan: resilver in progress since Tue Oct  6 14:00:00 2026
	250G scanned at 850M/s, 120G issued at 400M/s, 500G total
	120G resilvered, 24.00% done, 00:15:45 to go
```

- リシルバリングが完了するまで，マシンの電源を切ったり重い負荷をかけたりしないこと．

### Step 4: 完了確認とエラーカウンタのクリア

リシルバリングが完了すると，プールのステータスが `ONLINE` に復帰する．

1. スキャン結果が `resilvered <SIZE> in ... with 0 errors` となっていることを確認する．
2. 過去のエラーカウンタをリセットする:
   ```bash
   sudo zpool clear tank-1tb
   ```
3. プールが完全に正常化したことを最終確認する:
   ```bash
   zpool status -x
   # "all pools are healthy" と出力されれば完了
   ```

---

## 関連ドキュメント

- [ホスト概要: `hosts/shosoin-tan/README.md`](../../hosts/shosoin-tan/README.md)
- [システム構成: `hosts/shosoin-tan/default.nix`](../../hosts/shosoin-tan/default.nix)
- [ハードウェア定義: `hosts/shosoin-tan/hardware.nix`](../../hosts/shosoin-tan/hardware.nix)
- [ホスト概要: `hosts/sando-kun/README.md`](../../hosts/sando-kun/README.md)
- [システム構成: `hosts/sando-kun/default.nix`](../../hosts/sando-kun/default.nix)
- [バックアップ運用手順: `docs/operations/backup-and-restore.md`](../operations/backup-and-restore.md)
