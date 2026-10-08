# AMD + NVIDIA ハイブリッド GPU 分離設計ガイド

本ドキュメントは，AMD Ryzen 7 6800H（内蔵 GPU: Radeon 680M）とハードウェア障害を抱えた NVIDIA GeForce RTX 3050 Ti Laptop GPU を搭載したホスト（`BrokenPC` / HP Victus 16-e1065AX）における，Wayland 描画隔離と CUDA 推論専用オフロードの分離設計仕様をまとめたものである．本機は拠点A をベースとしつつ，外出時にも持ち出されるサブ機（可搬ノートPC）としての運用特性を持つ．

---

## 1. システム構成と障害の切り分け

### ハードウェア構成

| 項目 | 諸元・仕様 |
| :--- | :--- |
| **対象ホスト** | `BrokenPC`（HP Victus 16-e1065AX）: サブ機（可搬ノートPC） |
| **CPU** | AMD Ryzen 7 6800H（Zen 3+，8コア / 16スレッド，基本 3.2 GHz / 最大 4.7 GHz） |
| **iGPU** | AMD Radeon 680M（Rembrandt，RDNA2，12 CU / 768 シェーダー，PCI `07:00.0`） |
| **dGPU** | NVIDIA GeForce RTX 3050 Ti Mobile（GA107，Ampere，4 GB GDDR6，PCI `01:00.0`）※**物理障害あり** |
| **RAM** | 16 GB DDR5-4800 |
| **ストレージ** | 512 GB NVMe（OS / Boot），1 TB NVMe（`/data`） |

### 障害の症状と切り分け

- **症状**: Minecraft 等の重い 3D レンダリングを実行すると，OpenGL 環境では `libnvidia-glcore.so` 内で `SIGSEGV` が発生し，Vulkan 環境では GPU ハング（画面フリーズおよびドライバのリセットタイムアウト）が発生する．
- **切り分け実験**:
  - `glmark2` ベンチマークは完走する．
  - VRAM の 90% 以上を確保するメモリストレステストはエラーなく通過する．
- **結論**:
  - VRAM チップそのものやカーネルドライバの欠陥ではなく，dGPU 内部の **3D レンダリングパイプラインおよびテクスチャアップロード回路に物理的破損** が生じている．
  - 一方で，AMD Radeon 680M iGPU は極めて安定して 3D アプリケーションを実行可能である．

---

## 2. デスクトップ・描画パイプラインの隔離設計

物理破損を抱える dGPU が描画パイプラインに関与すると，デスクトップ環境（コンポジタ）やアプリケーションが巻き込まれてクラッシュする．そのため，**表示・描画から dGPU を完全に排除し，AMD iGPU のみで完結させる** 設計を採用している．

### Wayland (Niri) レンダラの iGPU 固定 (`WLR_DRM_DEVICES`)

Niri（wlroots ベースの Wayland コンポジタ）において，プライマリ DRM デバイスを AMD iGPU に固定する．

```ini
# ~/.config/systemd/user/niri.service.d/wlr-drm-devices.conf
[Service]
Environment="WLR_DRM_DEVICES=/dev/dri/by-path/pci-0000:07:00.0-card,/dev/dri/by-path/pci-0000:01:00.0-card"
```

#### 設定の要点と設計判断

1. **`/dev/dri/by-path` の採用理由**:
   `/dev/dri/card0` や `card1` といった動的デバイス名は，カーネルのモジュール初期化順序によってブートごとに番号が入れ替わるリスクがある．PCI バスアドレスに基づくシンボリックリンク（AMD iGPU: `07:00.0`，NVIDIA dGPU: `01:00.0`）を明示することで，常に AMD iGPU がプライマリレンダラとして選択されることを保証する．
2. **Home Manager ドロップインによる定義理由**:
   NixOS システムモジュール側で `systemd.user.services.niri` を定義すると，niri パッケージが提供する既定の Unit 定義が丸ごと上書きされ，肝心の `ExecStart` 行が欠落する．また，`/etc/systemd/user` は Nix store へのシンボリックリンクであり `environment.etc` によるインプレース追記ができない．そのため，[`hosts/BrokenPC/default.nix`](../../hosts/BrokenPC/default.nix) 内の Home Manager 設定経由で `xdg.configFile."systemd/user/niri.service.d/wlr-drm-devices.conf"` を配置している．

### ゲーム描画における dGPU オフロード無効化

- **ゲーム実行方針**: Steam や各種ゲームを起動する際，PRIME オフロード（`nvidia-offload`）を使用せず，Radeon 680M 上でネイティブ描画を行う．
- **設定**: `my.services.desktop.gaming.nvidiaOffload.enable = false`（既定値の無効状態）を維持し，dGPU の 3D 描画呼び出しによるクラッシュを未然に防止している．

### 省電力制御 (RTD3 & finegrained)

描画から除外された dGPU を常時通電させておくと，無駄な電力消費と発熱が発生する．特に BrokenPC は外部へ持ち出される可搬ノートPCでもあるため，dGPU の無駄な電力消費はバッテリー駆動時間を著しく損なう．NVIDIA オープンカーネルモジュールと RTD3（Runtime D3）を併用することで，アイドル時に dGPU の電源を完全にオフにしている．

```nix
# hosts/BrokenPC/default.nix
my.hardware.nvidia = {
  enable = true;
  open = true; # オープンカーネルモジュールを使用
  powerManagement = {
    enable = true;
    finegrained = true; # RTD3 動的電源管理を有効化
  };
  prime = {
    enable = true;
    offload.enable = true;
    sync.enable = false; # ディスプレイ同期出力は無効
    nvidiaBusId = "PCI:1:0:0";
    amdgpuBusId = "PCI:7:0:0";
  };
};
```

これにより，後述の CUDA 計算タスクが実行されていない平常時，dGPU は自動的に省電力スリープ（電源遮断状態）を維持する．

---

## 3. CUDA / llama.cpp 推論専用オフロード

テクスチャアップロード回路が破損している一方で，テクスチャ転送を伴わない純粋な **行列積演算（GEMM）およびテンソル並列計算パイプライン（CUDA コア / Tensor コア）は正常に機能する**．この特性を活かし，大規模言語モデル（LLM）の推論アクセラレータとして dGPU を活用している．

### ビルドアーキテクチャの指定

Nixpkgs に対し，GA107 コア（Ampere アーキテクチャ）向けの最適化コードを生成するよう指定している．

```nix
# hosts/BrokenPC/default.nix
nixpkgs.config.cudaCapabilities = [ "8.6" ];
```

これにより，不要なアーキテクチャのバイナリ肥大化を避け，RTX 3050 Ti（Compute Capability 8.6）に特化した最速の CUDA カーネルがビルドされる．

### llama.cpp サービス構成とメモリチューニング

推論バックエンドとして [`hosts/BrokenPC/services/llama.nix`](../../hosts/BrokenPC/services/llama.nix) にて `llama-server` を運用している．

```nix
home-manager.users.${config.my.user.name} = {
  my.services.llama = {
    enable = true;
    enableCuda = true;
    modelsDir = "/data/llama/models";
    modelsMax = 1;
    sleepIdleSeconds = 300; # アイドル 5 分でモデル解放・GPU 電源オフ
    presets = {
      # 3B/4B: VRAM に完全オフロード
      "G9v3-3B-Q4_K_M" = {
        ngl = 99;
        ncmoe = 0;
        ctxSize = 32768;
      };
      "Qwen3.5-4B-Q4_K_M" = {
        ngl = 99;
        ncmoe = 0;
        ctxSize = 16384;
      };
      # 9B: 一部層のみ GPU オフロード（VRAM 4GB 制限）
      "Qwen3.5-9B-Q4_K_M" = {
        ngl = 12;
        ncmoe = 0;
        ctxSize = 32768;
      };
      "Ornith-1.5-9B-Q4_K_M" = {
        ngl = 12;
        ncmoe = 0;
        ctxSize = 32768;
      };
      # MoE / 小型モデル: --fit による自動フィッティングに委ねる
      "Ling-3.0-tiny-Q4_K_M" = { };
      "Ling-3.0-tiny-Uncensored-Abliterated.Q8_0" = { };
      "LFM2.5-8B-A1B-Q4_0" = { };
    };
  };
};
```

#### 4 GB VRAM 環境におけるチューニング要点

1. **モデル規模別の層オフロード (`ngl`)**:
   - **3B / 4B クラス**: `ngl = 99` を指定し，全レイヤを 4 GB VRAM 内へ完全に格納して超高速推論を実現する．
   - **9B クラス**: VRAM 容量を超えるため，`ngl = 12` により先頭の 12 レイヤのみを GPU へオフロードし，残りは CPU（Ryzen 7 6800H）および DDR5 RAM で処理する．
2. **`--fit` オプションによる動的 MoE オフロード**:
   - `presets` 内で設定値を空集合 `{}` としたモデルは，設定 INI ファイルからキーが省略される．
   - これにより，`llama-server` の `--fit` フラグが有効化され，4 GB の VRAM 枠に収まるよう自動的にレイヤ数，コンテキスト長，MoE エキスパート数が最適配分される（手動で `ngl` や `ncmoe` を与えると `--fit` が無効化されるため）．
3. **アイドル時の電源復帰 (`sleepIdleSeconds = 300`)**:
   - 推論リクエストが途絶えて 300 秒（5 分）経過するとモデルをメモリから解放する．
   - これに連動して dGPU への CUDA コンテキストが破棄され，前述の RTD3 機構により dGPU が自動的に電源遮断（サスペンド）状態に戻る．

---

## 関連ドキュメント

- [ホスト概要: `hosts/BrokenPC/README.md`](../../hosts/BrokenPC/README.md)
- [ホスト定義: `hosts/BrokenPC/default.nix`](../../hosts/BrokenPC/default.nix)
- [ハードウェア構成: `hosts/BrokenPC/hardware.nix`](../../hosts/BrokenPC/hardware.nix)
- [推論サービス定義: `hosts/BrokenPC/services/llama.nix`](../../hosts/BrokenPC/services/llama.nix)
