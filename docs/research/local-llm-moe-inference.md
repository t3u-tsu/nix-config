# ローカル LLM MoE 推論と BrokenPC 実機ベンチマーク

2026-11 時点のローカル LLM 推論基盤技術の調査と，`BrokenPC` (VRAM 4 GiB / RAM 14 GiB) における `llama.cpp` 実機ベンチマークの記録．

| 項目 | 要件・確認事項 |
| :--- | :--- |
| 対象ホスト | `BrokenPC` |
| CPU / RAM | AMD Ryzen 7 6800H (8 コア / 16 スレッド) / 14 GiB (NVMe Swap 31 GiB) |
| GPU | NVIDIA GeForce RTX 3050 Ti Mobile (VRAM 4,096 MiB) + AMD Radeon 680M |
| upstream リビジョン | `llama.cpp` `1.0.0-dev` (flake rev `1719dbb`, CUDA 対応，`lfm2moe`・`llm-jp-harmony-v1` 対応済み) |
| サービス定義 | [nixos/services/llama/default.nix](../../nixos/services/llama/default.nix)，[hosts/BrokenPC/services/llama.nix](../../hosts/BrokenPC/services/llama.nix) |

---

## 1. 概要と結論

| 問い | 回答 | 判定 |
| :--- | :--- | :--- |
| MoE VRAM キャッシュ (`--moe-cache-mib`) の効果はあるか | `--moe-cache-mib 1024` (`gemma-4` / 32B 級は `512`) と `--moe-cache-cpu-share 0.0` でホットなエキスパートを VRAM へ保持すると，`LFM2.5-24B-A2B` は `6.23 tok/s` → `14.45 tok/s` (約 2.3 倍)，軽量 MoE (`LFM2.5-8B-A1B`, `Ling-3.0-tiny`) は 4 倍超に高速化する | Confirmed |
| KV キャッシュ量子化 `q8_0` は有効か | `-ctk q8_0 -ctv q8_0` で精度劣化をほぼ抑えたまま容量を半減できる．`LFM2.5-24B-A2B` で 64K / 128K，`gemma-4-26B-A4B` で 64K，`G9v3-3B` で 32K が安定動作する | Confirmed |
| Ryzen 7 6800H の最適スレッド数はいくつか | `-t 12 -tb 16` が最速である (`LFM2.5-24B-A2B`, `-c 32768`, `--moe-cache-mib` なし時: `-t 4` で `3.65`, `-t 8` で `5.83`, `-t 12` で `6.99`, `-t 16` で `6.24 tok/s`)．12 スレッドでシステム RAM 帯域の飽和を避けられる | Confirmed |
| `--load-mode none` と `mmap` のどちらを使うべきか | 既定の `mmap` を維持する．14 GiB RAM 環境で 12〜16 GiB モデルに `--load-mode none` + `-c 32768` を指定すると匿名メモリ確保で OOM が発生する．`mmap` なら OS がクリーンページを回収し Swap `0 kB` で動作する | Direct Root Cause |
| `--cache-ram` の既定値は安全か | `llama-server` のプロンプトキャッシュ RAM 上限は既定 `8192 MiB` であり，14 GiB RAM 環境では過大である．`-cram 1024` (`--cache-ram 1024`) へ制限して OOM を防ぐ | Mitigated |
| `--spec-type ngram-cache` はチャット用途で有効か | 自由記述の日本語チャット (`LFM2.5-24B-A2B`) では受容率が `16.6〜18.9%` に留まり，検証負荷で `14.4 tok/s` → `5.1〜7.1 tok/s` へ低下する．無効 (既定) が最適である | Ruled Out |

---

## 2. アーキテクチャと量子化方式

### 2.1 MoE オフロードとハイブリッド構造

`llama.cpp` v1.0 系では `--fit on` と `-ngl auto` が既定であり，Attention / Conv 層や KV キャッシュを GPU VRAM に残し，大容量の MoE エキスパート重みをシステム RAM に置く細粒度オフロード (`--n-cpu-moe`, `-ot`) が自動計算される．`-ngl` や `-c` を固定せず省略 (または必要な `-c` のみ指定) すると，空き VRAM に合わせた層分割が選ばれる．

動的 MoE VRAM キャッシュは，ホットなエキスパートを VRAM へ保持する仕組みである．`llama.cpp` では `--moe-cache-mib` として統合されている．特化型エンジンとしては VRAM → RAM → NVMe SSD の 3 階層キャッシュと `io_uring` + `O_DIRECT`・プロファイルに基づく連続配置で 100B+ MoE を単一 GPU で動かす Strata (`Niko1221/Strata`, `Cintu07/strata`) がある．

モデル構造面では，`LFM2.5-24B-A2B` が全 40 層のうち GQA (Attention) を 10 層のみ (残り 30 層は ShortConv) に抑えたハイブリッド構造を採るため，全層 Attention モデルに比べて長コンテキスト時の KV キャッシュ消費が小さい．4 GiB VRAM 環境における現実的なコンテキスト長上限は次のとおりである．

| モデル分類 | 代表モデル | KV 設定 | 現実的なコンテキスト長 |
| :--- | :--- | :--- | :--- |
| ハイブリッド MoE | `LFM2.5-24B-A2B` | `f16` / `q8_0` | `f16` で 64K，`-ctk q8_0 -ctv q8_0` 併用でネイティブ最大 128K (`131,072`) |
| 標準型 MoE | `ELYZA-32B-A3B` / `gemma-4-26B-A4B` | `q8_0` | 32K〜64K |
| 小型 Dense (全層 VRAM) | `G9v3-3B` | `q8_0` | 32K (64K では VRAM 溢れにより速度が急落する) |

KV キャッシュ圧縮技術としては，`q8_0` (`-ctk q8_0 -ctv q8_0`) が容量半減・精度劣化ほぼ無しの実用標準であり，さらなる長文向けに `q4_0` や FP8 がある．研究動向として，直交回転 + PolarQuant + 残差補正 (`QJL`) により再学習なしで KV キャッシュを 3〜4 bit へ圧縮 (4〜6 倍削減) する TurboQuant (ICLR 2026, Google Research) も報告されている．

### 2.2 4-bit クラス量子化方式の比較

| 方式 | 特徴 | 用途 |
| :--- | :--- | :--- |
| `Q4_K_M` | 固定レシピで一部重要層を 6/8-bit に保つ標準形式 | 互換性・安定性重視のベースライン |
| `IQ4_XS` / `IQ3_*` | `imatrix` により重要重みを保護する高圧縮形式 | 容量制約下で精度を保つ場合 (CPU デコード負荷はやや高い) |
| `Q3_K_S` | 3-bit クラスの高圧縮形式 | `ELYZA-32B-A3B` (`14.32 GiB`) を 14 GiB RAM 境界へ近づける用途 |
| `MXFP4` | 共有スケール付きハードウェア指向 4-bit 浮動小数点 | 対応ハードウェアでのネイティブ実行向け |
| `UD` (Unsloth Dynamic) | 層ごとにビット幅・方式を動的に割り当てる方式 | 推論・コーディング劣化を抑える場合 (`gemma-4-26B-A4B-it-UD-IQ4_XS`) |
| `QAD` (Liquid AI) | 学習段階から `Q4_0` 制約で量子化認識蒸留を行う方式 | `Q4_0` の軽さ・SIMD 親和性と `Q5_K_M` 級の精度の両立 |

---

## 3. 実機ベンチマーク比較 (`BrokenPC`)

### 3.1 モデル別最適条件と性能比較

共通スレッド設定は `-t 12 -tb 16` である．

| モデル | サイズ | 総 / 活性 | 最適条件 | Load | Prompt Eval | Generation |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `LFM2.5-24B-A2B-QAD-Q4_0` | 12.65 GiB | 24B / 2.45B | `-c 32768 -fitt 256 --moe-cache-mib 1024` | 5.2 s | 7.81 tok/s (長文 149 tok/s) | 14.45 tok/s |
| `LFM2.5-24B-A2B-QAD-Q4_0` | 12.65 GiB | 24B / 2.45B | `-c 65536 -ctk q8_0 -ctv q8_0 -fitt 256 --moe-cache-mib 1024 --moe-cache-cpu-share 0.0` | 4.2 s | 10.39 tok/s | 14.39 tok/s |
| `LFM2.5-24B-A2B-QAD-Q4_0` | 12.65 GiB | 24B / 2.45B | `-c 131072 -ctk q8_0 -ctv q8_0 -fitt 256 --moe-cache-mib 768 --moe-cache-cpu-share 0.0` | 6.5 s | 6.26 tok/s | 10.84 tok/s |
| `gemma-4-26B-A4B-it-UD-IQ4_XS` | 12.66 GiB | 26B / ~4B | `-c 65536 -ctk q8_0 -ctv q8_0 -fitt 256 --moe-cache-mib 512 --moe-cache-cpu-share 0.0` | 15.4 s | 1.86 tok/s | 4.77 tok/s |
| `ELYZA-32B-A3B-Q3_K_S` | 14.32 GiB | 32B / ~3.8B | `-c 16384 -ctk q8_0 -ctv q8_0 -fitt 256 --moe-cache-mib 1024 --moe-cache-cpu-share 0.0` | 14.7 s | 2.76 tok/s | 2.98 tok/s |
| `ELYZA-32B-A3B-IQ4_XS` | 16.37 GiB | 32B / ~3.8B | `-c 16384 -ctk q8_0 -ctv q8_0 -fitt 256 --moe-cache-mib 512` | 20.2 s | 1.92 tok/s (128 tok 時 3.04) | 1.97 tok/s (128 tok 時 2.53) |
| `LFM2.5-8B-A1B-Q4_0` | 4.6 GiB | 8B / 1B | `-c 32768 -ctk q8_0 -ctv q8_0 -fitt 256 --moe-cache-mib 1024 --moe-cache-cpu-share 0.0` | 0.9 s | 61.09 tok/s | 61.96 tok/s |
| `Ling-3.0-tiny-Q8_0` | 7.9 GiB | MoE (Q8) | `-c 32768 -ctk q8_0 -ctv q8_0 -fitt 256 --moe-cache-mib 1024 --moe-cache-cpu-share 0.0` | 2.4 s | 37.63 tok/s | 46.23 tok/s |
| `Qwen3.5-9B-Q4_K_M` | 5.3 GiB | 9B Dense | `-c 32768 -ctk q8_0 -ctv q8_0 -fitt 256` | 2.4 s | 7.48 tok/s | 6.18 tok/s |
| `G9v3-3B-Q4_K_M` | 1.8 GiB | 3B Dense | `-c 32768 -ctk q8_0 -ctv q8_0 -fitt 256` | 1.0 s | 455.25 tok/s | 81.16 tok/s |

### 3.2 同サイズモデルの速度差 (`LFM2.5-24B` vs `gemma-4-26B`)

ファイルサイズは `12.65 GiB` と `12.66 GiB` でほぼ同一だが，生成速度には約 3 倍の差が生じた．`LFM2.5-24B-A2B-QAD-Q4_0` は Attention が 10 層のみ・活性 2.45B・軽量な `Q4_0` 形式であるため，4 GiB VRAM に全 Attention/Conv 層と `1024 MiB` の MoE キャッシュが収まり `14.45 tok/s` (-c 32768) / `14.39 tok/s` (-c 65536) を記録した．

一方 `gemma-4-26B-A4B-it-UD-IQ4_XS` は全層 Attention・活性 ~4B・`IQ4_XS` 形式であるため，GPU 収容層が `20〜25` 層に留まる．コンテキストと MoE キャッシュごとの推移は次のとおりである．

| 条件 (`gemma-4-26B-A4B-it-UD-IQ4_XS`) | GPU 層数 | Generation |
| :--- | :--- | :--- |
| `-c 4096` (既定) | `-ngl 15` | 4.15 tok/s |
| `-c 32768 -ctk q8_0 -ctv q8_0 -fitt 256 --moe-cache-mib 512 --moe-cache-cpu-share 0.0` | `-ngl 25` | 4.68 tok/s |
| `-c 32768` + `--moe-cache-mib 1024` | `-` | 3.97 tok/s (キャッシュ過大で GPU 層が減少し低下) |
| `-c 65536 -ctk q8_0 -ctv q8_0 -fitt 256 --moe-cache-mib 512 --moe-cache-cpu-share 0.0` | `-ngl 20` | 4.77 tok/s |

### 3.3 14 GiB RAM の制約 (`ELYZA-32B-A3B`)

`ELYZA-32B-A3B-IQ4_XS` (`16.37 GiB`) は物理 RAM (14 GiB) を超えるため NVMe リード律速となり，`1.5〜2.5 tok/s` (最適設定で `1.97 tok/s`，128 tok 時 `2.53 tok/s`) に留まる．`ELYZA-32B-A3B-Q3_K_S` (`14.32 GiB`) へ落とすことで最大 `2.98 tok/s` まで改善した．なお，`llama.cpp` rev `1719dbb` には `llm-jp-harmony-v1` が統合済みであり，パッチなしで日本語思考が出力される．

---

## 4. スレッド数・キャッシュ・OOM 回避

### 4.1 CPU スレッド数と MoE キャッシュのリソースプロファイル

`LFM2.5-24B-A2B-QAD-Q4_0` (`-c 32768 -tb 16`, `--moe-cache-mib` なし) で `-t` を変化させた場合，Ryzen 7 6800H では `-t 12` が最速となった．

| `-t` | Generation |
| :--- | :--- |
| `-t 4` | 3.65 tok/s |
| `-t 8` | 5.83 tok/s |
| `-t 12` | 6.99 tok/s |
| `-t 16` | 6.24 tok/s |

`--moe-cache-mib 1024` の有無による `LFM2.5-24B-A2B-QAD-Q4_0` のリソース使用状況は次のとおりである．

| 条件 | CPU 使用率 | GPU 使用率 (電力) | VRAM | RSS | Swap |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `--moe-cache-mib` なし | 918% | 2〜5% | 2,675 MiB | 13.06 GiB | 0 kB |
| `--moe-cache-mib 1024` | 146% | 65〜77% (32〜34 W) | 2,729 MiB | 12.7 GiB | 0 kB |

`llama-server` の投機的デコード (`--spec-type ngram-cache`) を自由記述の日本語チャット (`LFM2.5-24B-A2B`) で検証したところ，受容率は `16.6〜18.9%` に留まり，検証コストにより生成速度が `14.4 tok/s` → `5.1〜7.1 tok/s` へ低下した．

### 4.2 OOM 回避と VRAM 詰め込みパラメータ

1. `--load-mode none` を使わず `mmap` (既定) を維持する．14 GiB RAM 環境で 12〜16 GiB モデルに対し `--load-mode none` と `-c 32768` を併用すると匿名メモリ確保で OOM が発生する．既定の `mmap` であれば OS がクリーンページを回収でき，Swap `0 kB` で動作する．
2. `--cache-ram 1024` (`-cram 1024`) を指定する．`llama-server` のプロンプトキャッシュ RAM 上限は既定で `8192 MiB` と大きいため，14 GiB RAM 環境では上限を絞って OOM を防ぐ．
3. `-fitt 256 --moe-cache-mib 1024 --moe-cache-cpu-share 0.0` (`gemma-4` や 32B クラスでは `--moe-cache-mib 512`) と `-ctk q8_0 -ctv q8_0` を併用する．空き VRAM マージンを `256 MiB` に詰め，KV キャッシュを半減させることで 4 GiB VRAM 環境での層収容と MoE キャッシュを両立できる．

### 4.3 NixOS サービス設定との対応

[nixos/services/llama/default.nix](../../nixos/services/llama/default.nix) は `my.services.llama` として `enable`, `enableCuda`, `modelsDir`, `modelsMax`, `port`, `host`, `threads`, `threadsBatch`, `cacheRam`, `sleepIdleSeconds`，および `presets` (`ngl`, `ncmoe`, `ctxSize`, `fitTarget`, `cacheTypeK`, `cacheTypeV`, `moeCacheMib`, `moeCacheCpuShare`) を提供し，未設定のプリセット項目を INI から省略して `--fit` の自動メモリ割り当てを有効に保つ．[hosts/BrokenPC/services/llama.nix](../../hosts/BrokenPC/services/llama.nix) では `threads = 12`, `threadsBatch = 16`, `cacheRam = 1024` を設定したうえで，`ngl` と `ncmoe` を省略して `--fit` に委ねつつ，`LFM2.5-24B-A2B-QAD-Q4_0`, `gemma-4-26B-A4B-it-UD-IQ4_XS`, `ELYZA-Thinking-1.0-llm-jp-4-32b-a3b-Q3_K_S`, `ELYZA-Thinking-1.0-llm-jp-4-32b-a3b-IQ4_XS` を含む各プリセットへ `ctxSize`, `cacheTypeK`, `cacheTypeV`, `fitTarget`, `moeCacheMib`, `moeCacheCpuShare` を設定している．

---

## 関連ドキュメント

- [目次](../README.md) — 全ドキュメントの索引
- [hybrid-gpu.md](../hardware/hybrid-gpu.md) — `BrokenPC` のハイブリッド GPU 分離と CUDA オフロード
- [nixos/services/llama/default.nix](../../nixos/services/llama/default.nix) — `my.services.llama` モジュール定義
- [hosts/BrokenPC/services/llama.nix](../../hosts/BrokenPC/services/llama.nix) — `BrokenPC` の `llama-server` プリセット設定
