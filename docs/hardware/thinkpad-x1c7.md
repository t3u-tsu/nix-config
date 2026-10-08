# ThinkPad X1 Carbon Gen 7 ハードウェア構成と最適化ガイド

本ドキュメントは，Lenovo ThinkPad X1 Carbon Gen 7（ホスト名: `x1c7`）におけるハードウェア仕様，電源・サーマル管理，ログイン認証，スリープ動作，およびオーディオ消失回避ワークアラウンドに関する技術仕様と設計要点をまとめたものである．

---

## 1. ハードウェア諸元と NixOS 最適化

### 基本仕様

| 項目 | 構成内容 |
| :--- | :--- |
| **CPU** | Intel Core i7-8565U（Whiskey Lake-U，4コア / 8スレッド，1.80 GHz - 4.60 GHz） |
| **iGPU** | Intel UHD Graphics 620（Gen 9.5） |
| **RAM** | 16 GB LPDDR3-2133（オンボード実装，増設不可） |
| **ストレージ** | Samsung PM981 256 GB NVMe SSD（`MZVLB256HBHQ-000L7`） |
| **ディスプレイ** | 14インチ FHD（1920x1080）IPS BOE NE140FHM-N61（`eDP-1`） |
| **ネットワーク** | Intel Wireless-AC 9560（CNVi，`iwlwifi`）/ Bluetooth 5.0（`8087:0aaa`） |
| **Thunderbolt 3** | Intel JHL6540（Alpine Ridge，カーネルネイティブ管理） |
| **オーディオ** | Intel HDA with Sound Open Firmware（SOF DSP） |
| **入力 / センサー** | Synaptics I2C タッチパッド & TrackPoint，Synaptics Prometheus 指紋センサー（`06cb:00bd`） |
| **セキュリティ** | STMicroelectronics TPM 2.0（LUKS 移行準備用） |

### カーネル選定とハードウェアモジュール

- **カーネル**: [`pkgs.linuxPackages_xanmod`](../../hosts/x1c7/default.nix) を採用．デスクトップの対話的応答性とタスクスケジューリングの低レイテンシ化を図る．
- **nixos-hardware 連携**: [`nixos-hardware.nixosModules.lenovo-thinkpad-x1-7th-gen`](../../hosts/x1c7/default.nix) をインポートし，トラックポイント，Intel マイクロコード，VA-API，およびラップトップ／SSD 共通モジュールを導入している．

### メモリ・スワップチューニング (OOM 回避)

16 GB の限られた物理メモリ環境において，`rustc`，`nix`，`zig` などの並列ビルド（最大 8 スレッド）を実行すると単一プロセスが約 10 GB の無名メモリを消費し，OOM Killer が頻発する課題が存在した．これを解決するため，[`hosts/x1c7/hardware.nix`](../../hosts/x1c7/hardware.nix) にて以下のチューニングを実施している．

- **zram**: `memoryPercent = 100`，`priority = 100`．メモリ内圧縮スワップを最優先で使用し，実効メモリ容量を拡張する．
- **Swapfile**: 16 GiB（`/var/lib/swapfile`）．RAM 全体を退避可能なサイズを確保し，カーネルが割り当てる負の優先度により，通常時は zram が枯渇した後のオーバーフロー領域として機能する．
- **sysctl パラメータ**:
  - `vm.swappiness = 180`: 積極的な無名ページの圧縮スワップアウトを促す．
  - `vm.watermark_scale_factor = 125`: ページ回収の開始水準を引き上げ，突発的なメモリ確保時の OOM を防ぐ（NixOS デフォルトの `10` は回収開始が遅すぎる）．
  - `vm.watermark_boost_factor = 0`: ウォーターマーク急上昇に伴う不要な I/O スラッシングを抑止．
  - `vm.page-cluster = 0`: zram 向けに単一ページ単位での読み出し・書き出しを強制．

### ハイバネーション設計

- **`boot.resumeDevice` の非指定**: スワップはルートパーティション直下のファイル（`/var/lib/swapfile`）として配置されている．`boot.resumeDevice` にルートパーティションを指定するとカーネルコマンドラインに `resume=<partition>` が付与され，logind が「有効なスワップデバイスではない」としてハイバネーションを拒否する．UEFI + systemd initrd 環境では，`systemd-sleep` がスワップファイルを特定して `HibernateLocation` EFI 変数へ記録し，次回起動時に `systemd-hibernate-resume` が自動的にオフセットを読み出して復元する．
- **クリティカル電力保護**: [`services.upower.criticalPowerAction = "Hibernate"`](../../hosts/x1c7/services/power.nix) により，バッテリー枯渇時は強制シャットダウンではなくハイバネーションを実行してセッションを退避する．

---

## 2. 電源・サーマル管理 (TLP & throttled)

ThinkPad の電源・サーマル制御は，以下の 3 層構造で連携している．

1. **Platform Profile (ACPI DYTC)**: Lenovo の Embedded Controller (EC) にファンカーブとサーマルテーブルを指示（`/sys/firmware/acpi/platform_profile`）．
2. **Energy Performance Preference (Intel HWP EPP)**: CPU の自律的周波数スケーリング方針を制御（`/sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference`）．
3. **Scaling Governor (intel_pstate)**: カーネルドライバの動作モード（`/sys/devices/system/cpu/cpu*/cpufreq/scaling_governor`）．

設定は [`hosts/x1c7/services/power.nix`](../../hosts/x1c7/services/power.nix) に集約されている．

### TLP 設定要点

- **バッテリー充電閾値**: `START_CHARGE_THRESH_BAT0 = 75` / `STOP_CHARGE_THRESH_BAT0 = 80`．AC 常時接続環境におけるバッテリーセルの劣化を大幅に抑制する（満充電が必要な際は `sudo tlp fullcharge` で一時解除）．
- **D-Bus 連携 (`tlp.pd`)**: `services.tlp.pd.enable = true` により `net.hadess.PowerProfiles` D-Bus インターフェースを提供し，Noctalia デスクトップの `power_profile` バーウィジェットからプロファイルをシームレスに切り替え可能としている．
- **XanMod と intel_pstate の競合解消**:
  - XanMod カーネルは `CONFIG_CPU_FREQ_DEFAULT_GOV_PERFORMANCE=y` でビルドされる．
  - しかし，`intel_pstate` のアクティブモード下で governor を `performance` にすると，EPP が 0（performance）に固定され，EPP の書き換えが `EBUSY` で拒否されてアイドル時にクロックが下がらなくなる．
  - そのため，AC / バッテリー双方で governor を `powersave` に強制し，EPP（AC: `balance_performance`，BAT: `balance_power`）が正しく自律動作するように制御している．
- **動的ブーストと省電力**:
  - `CPU_HWP_DYN_BOOST_ON_AC = 1`: AC 駆動時の急激な負荷スパイクに対し動的ブーストを適用し UI 応答性を維持．
  - `PLATFORM_PROFILE = "balanced"`: AC / BAT ともに静音性を維持しつつ，高負荷時は Noctalia ウィジェットから性能モードへ引き上げ可能．
  - `PCIE_ASPM_ON_BAT = "powersave"`: バッテリー駆動時に PCIe リンク（NVMe，Wi-Fi，Thunderbolt）を低電力ステートへ移行．

### throttled (Lenovo サーマルバグ対策)

Linux 環境において，Lenovo の EC ファームウェアが CPU を過剰に早期スロットリングする既知バグが存在する．これを回避するため [`throttled`](https://github.com/erpalma/throttled) を運用している．

薄型軽量筐体の冷却限界（シングルファン・デュアルヒートパイプ）を踏まえ，CPU 仕様（Intel Core i7-8565U）に適合した制限値へ調律している．

| モード | パラメータ | 設定値 | 設計意図 |
| :--- | :--- | :--- | :--- |
| **AC 駆動** | `PL1_Tdp_W` | 25 W（28秒） | Configurable TDP-up 上限．重いビルド時にも全コア ~3.0 GHz を維持． |
| | `PL2_Tdp_W` | 35 W（0.002秒） | 短時間のバースト負荷をヒートパイプの熱容量で吸収． |
| | `Trip_Temp_C` | 90 ℃ | TjMax（100 ℃）手前で PL2 バーストを許容しつつ筐体温度を制御． |
| **バッテリー** | `PL1_Tdp_W` | 15 W（28秒） | 公称 TDP に抑え，膝上使用時の温度と消費電力を両立． |
| | `PL2_Tdp_W` | 25 W（0.002秒） | UI 応答性を損なわない瞬間バースト枠． |
| | `Trip_Temp_C` | 85 ℃ | 低温での安全マージンを確保． |

- **電圧オフセット (Undervolt) の省略**: Whiskey Lake 世代では BIOS ファームウェアにより MSR 0x150 への書き込みがロックされているため，電圧オフセット指定は除外している．
- **設定反映の注意点**: Nix store 内の設定ファイルは更新時も mtime が変化しないため，throttled の Autoreload 機能は発火しない．設定変更後は必ず手動で再起動する:
  ```bash
  sudo systemctl restart throttled
  ```

---

## 3. ディスプレイ・ログイン認証 (Noctalia Greeter & 指紋認証)

### Noctalia Greeter

デスクトップログイン環境には Greetd ベースの [`noctalia-greeter`](../../nixos/services/desktop/greetd.nix) を採用している．

- **出力固定**: `my.services.desktop.greetd.greeterOutput.name = "eDP-1"` により内蔵ディスプレイにグリーターを表示．
- **権限分離と壁紙転送**: グリーターは非特権ユーザー（`greeter`）で動作する．ユーザーホーム（権限 `0700`）内の壁紙ファイルを直接読み取れないため，`systemd.services.noctalia-greeter-wallpaper` を通じて `/var/lib/noctalia-greeter/wallpaper.jpg` へ安全にコピーしてパーミッションを解決している．

### 指紋認証 (fprintd)

内蔵指紋リーダーは Synaptics Prometheus（`06cb:00bd`）であり，標準の `libfprint` ドライバで認識される．

- **有効化**: [`services.fprintd.enable = true`](../../hosts/x1c7/default.nix)
- **PAM 統合**: NixOS は `fprintd` 有効化時に `pam_fprintd.so` を `sufficient` として `sudo`，`su`，`polkit-1`，`greetd`，`swaylock` など 22 の PAM サービスに自動挿入する．指紋認証に失敗した場合は直ちにパスワードプロンプトへフォールバックするため，リーダー故障時にもロックアウトされない．
- **登録手順**:
  センサーはタッチ式（押して離す動作）である．スワイプ動作では認識されない．
  ```bash
  fprintd-enroll                        # 現在のユーザーの右手人差し指を登録
  fprintd-enroll -f left-index-finger   # 特定の指を指定して登録
  fprintd-verify                        # 読み取り検証
  fprintd-list "$USER"                  # 登録済み指紋の一覧
  ```

---

## 4. サスペンド動作と S3 Deep Sleep

### S3 vs s2idle のトレードオフ

BIOS 設定の `Config -> Power -> Sleep State` は **Linux (S3)** に設定している．

- **S3 (Deep Sleep)**: RAM 以外の給電をカットするためスリープ中のバッテリー消費を最小限に抑えられる．
- **s2idle (Modern Standby)**: 復帰が極めて高速で，復帰時の指紋センサー初期化の信頼性に優れるが，スリープ中の電力消費が大きい．

本ホストではバッテリー持続時間を優先して S3 を選択している．スリープステートの S3 deep への固定は，カーネルパラメータ（`mem_sleep_default=deep` など）ではなく，BIOS 設定の `Config -> Power -> Sleep State` を **Linux (S3)** に設定することで ACPI レベルで実現される．

### 運用上の留意事項

1. **Bluetooth 接続中のサスペンド**: Bluetooth デバイスが接続された状態でサスペンドすると即座に起床する既知の問題がある．サスペンド前に周辺機器を切断することが推奨される．
2. **リッドクローズ動作**: [`services.logind.settings.Login.HandleLidSwitchExternalPower = "lock"`](../../hosts/x1c7/default.nix) により，AC 給電時のディスプレイ開閉は画面ロックのみにとどめ，外部モニタ運用やビルドの中断を防ぐ．

---

## 5. オーディオ消失回避ワークアラウンド (ALSA UCM & PipeWire)

### 障害の技術的背景

ThinkPad X1C7 の Intel SOF HDA DSP 環境では，外部ディスプレイ（HDMI）を接続した際に ALSA UCM（Use Case Manager）の判定ロジックにより以下の競合が発生する．

1. HDMI 接続を検出すると，ALSA UCM 上で Headphones（アナログヘッドホン）プロファイルが誤って「利用可能」状態へ遷移する．
2. Headphones の `PlaybackPriority` が内蔵 Speaker（200）よりも高い値に設定されているため，PipeWire および WirePlumber が内蔵スピーカーのオーディオシンクを「不要な代替デバイス」と判定して破棄・非表示にする．
3. 結果として，HDMI を接続している間は内蔵スピーカーから音が出せなくなる．

### 適用されたワークアラウンド

[`hosts/x1c7/services/audio.nix`](../../hosts/x1c7/services/audio.nix) において，`alsa-ucm-conf` パッケージにパッチを適用し，PipeWire / WirePlumber に注入している．

```nix
let
  alsaUcmConf = pkgs.alsa-ucm-conf.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      ucm="$out/share/alsa/ucm2"

      # 1. HDMI と Headphones を排他化
      substituteInPlace "$ucm/codecs/hda/hdmi.conf" \
        --replace-fail \
          'Comment "HDMI / DisplayPort ''${var:__Number} Output"' \
          'Comment "HDMI / DisplayPort ''${var:__Number} Output"
			ConflictingDevice [ "Headphones" ]'

      # 2. ポートごとの優先度調整
      sed -i \
        -e '/Number 1/,/Priority/s/Priority 500/Priority 700/' \
        -e '/Number 2/,/Priority/s/Priority 600/Priority 100/' \
        -e '/Number 3/,/Priority/s/Priority 700/Priority 50/' \
        "$ucm/Intel/sof-hda-dsp/Hdmi.conf"

      # 3. 内蔵スピーカーの優先度を 900 に引き上げ
      substituteInPlace "$ucm/HDA/HiFi-analog.conf" \
        --replace-fail 'PlaybackPriority 200' 'PlaybackPriority 900'
    '';
  });
in
{
  # PipeWire と WirePlumber の双方に環境変数を設定
  systemd.user.services.pipewire.environment.ALSA_CONFIG_UCM2 = "${alsaUcmConf}/share/alsa/ucm2";
  systemd.user.services.wireplumber.environment.ALSA_CONFIG_UCM2 = "${alsaUcmConf}/share/alsa/ucm2";
}
```

### 要点

- **ConflictingDevice の追加**: HDMI 出力と Headphones デバイスを排他化（競合デバイス指定）することで，HDMI 接続時に Headphones プロファイルが誤発効することを防止する．
- **PlaybackPriority の逆転**: 内蔵スピーカーの優先度を `200` から `900` へ引き上げ，常に選択可能なプライマリシンクとして維持する．
- **両プロセスへの環境変数適用**: PipeWire だけでなく WirePlumber も ALSA カードを直接開いて UCM 設定を参照する．PipeWire 側のみに設定した場合，WirePlumber が標準の未パッチ UCM を読み込みスピーカーが再び消失するため，双方の systemd ユーザーサービスへ `ALSA_CONFIG_UCM2` を渡すことが不可欠である．

---

## 6. ファームウェア・BIOS 注意事項

### カスタム Secure Boot 鍵の登録リスク (文鎮化警告)

Lenovo ThinkPad X1 Carbon Gen 7 において，BIOS の Setup Mode を用いてカスタム Secure Boot 鍵（PK/KEK/db）を登録すると，マザーボードが POST に失敗して永久に起動不能（文鎮化 / brick）になるリスクが報告されている（Arch Linux Wiki 警告）．そのため，本機ではカスタム Secure Boot 鍵の自己登録は行わないこと．

### Thunderbolt BIOS Assist Mode の運用方針

BIOS の `Config -> Thunderbolt 3 -> Thunderbolt BIOS Assist Mode` は，Linux カーネル 4.13 以降で Thunderbolt のネイティブ管理がサポートされているため，**Disabled（無効）のまま運用** する．これを有効化すると過去の特定ファームウェアにおける不具合や電力管理の競合，起動障害を引き起こす恐れがあるため，ネイティブ Linux 管理を維持する．

---

## 関連ドキュメント

- [ホスト概要: `hosts/x1c7/README.md`](../../hosts/x1c7/README.md)
- [システム構成: `hosts/x1c7/default.nix`](../../hosts/x1c7/default.nix)
- [ハードウェア定義: `hosts/x1c7/hardware.nix`](../../hosts/x1c7/hardware.nix)
- [電源・サーマル設定: `hosts/x1c7/services/power.nix`](../../hosts/x1c7/services/power.nix)
- [オーディオパッチ: `hosts/x1c7/services/audio.nix`](../../hosts/x1c7/services/audio.nix)
- [デスクトップログイン設計: `nixos/services/desktop/greetd.nix`](../../nixos/services/desktop/greetd.nix)
