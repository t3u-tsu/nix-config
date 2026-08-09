# 調査メモ: linux-cachyos 7.1.6 の amdgpu リグレッション（BrokenPC 画面フリーズ）

2026-08-09 に BrokenPC（HP ノート, Ryzen 6000 Rembrandt 680M + RTX 3050 Ti）で発生した
画面の完全フリーズについて、原因調査と対応の記録。

## 結論

- 原因は **上流の Linux カーネル 7.1.6 の amdgpu/Display Core（DC）リグレッション**。
  カーネルバージョンそのものに起因する問題で、cachyos 特有ではない（vanilla 7.1.6 でも再現する）。
- 修正パッチは上流 **7.1.8 に予定**（AMD DRM work item #5567）。
- BrokenPC は当面 **nixpkgs 標準の `linuxPackages_xanmod`（6.18.41）** に切り替えた。

## 症状

- ブラウザ（zen-beta）起動など描画負荷がかかると、数秒〜数分後に**画面が完全にフリーズ**。
- 入力を受け付けず、画面も更新されない。**電源長押しでの強制再起動**のみで復帰。
- journal にはクラッシュの記録が残らない（ハードウェアリセットのため、直前ログがフラッシュされない）。

## ログ調査で判明したこと

- `coredumpctl` には該当クラッシュなし。カーネルパニック / OOM / GPU リセットの記録もなし。
- ブート履歴より、**10:19 に適用されたシステム更新（system-253, nixpkgs 26.05.20260807）後にクラッシュが開始**。
  それ以前のブート（カーネル 7.1.5）は 9 時間 55 分安定、zen-beta も連続動作。
- クラッシュは「ブラウザ起動」だけでなく、USB ドック接続時や起動直後にも発生（トリガーは複数）。
  → 共通因子は「7.1.6 の amdgpu/DC」。
- 毎ブート発生する NVIDIA の SBIOS アサーション（`failed to get target temp from SBIOS` 等）は
  8/2 から存在する恒常的なもので、今回のクラッシュとは無関係。

## 上流調査（一次ソース）

- **CachyOS/linux-cachyos issue #959**「[BUG] linux-cachyos 7.1.6: Plasma login screen freezes and turns black due to amdgpu pageflip timeouts」
  https://github.com/CachyOS/linux-cachyos/issues/959
  - 症状: `Pageflip timed out! This is a bug in the amdgpu kernel driver` / `flip_done timed out`
  - 影響: AMD iGPU（Rembrandt 680M 等）+ eDP 内蔵パネル + Wayland。AMD/AMD・AMD/NVIDIA の両方で発生。
  - **同一ハードウェア構成の報告あり**: HP Omen（Rembrandt 680M + RTX 3050 Ti）。
  - CachyOS 開発者 ptr1337「7.1.5→7.1.6 で CachyOS 側の変更はほぼない → 上流の問題」。
- **CachyOS/distribution issue #536**（Ryzen 7 6800H + 680M + RTX 3050, 私たちと同一構成）
  https://github.com/CachyOS/distribution/issues/536
- **AMD DRM work item #5567**「Kernel 7.1.6 - Rembrandt - AMDGPU error on Flip - Kwin - crtc->pflip_status != AMDGPU_FLIP_NONE」
  https://gitlab.freedesktop.org/drm/amd/-/work_items/5567
  - 修正パッチが **7.1.8 にキュー済み**（8/8 時点）。
- **Red Hat Bugzilla #2512106**「[amdgpu regression] Kernel 7.1.6-201 causes KWin atomic commit failures...」
  https://bugzilla.redhat.com/show_bug.cgi?id=2512106
  - NVIDIA 無関係・PSR 無関係であることを否定（`amdgpu.dcdebugmask=0x10` でも発生）。
  - 7.1.7 でも未修正。7.1.8 で修正予定。

## 修正パッチ（上流, Leo Li の 3 本）

1. `drm/amd/display: consolidate DCN vblank/flip handling onto vupdate_no_lock`
2. `drm/amd/display: check GRPH_FLIP status before sending event`
3. `Revert "drm/amd/display: Restore 5s vbl offdelay for NV3x+ DGPUs"`

参照: https://lists.freedesktop.org/archives/amd-gfx/ （amd-gfx メーリングリスト）

## 回避策の検討

| 方法 | 結果 |
|---|---|
| 7.1.5 へのロールバック | ✅ このマシンで 10 時間安定（実測） |
| `amdgpu.dcdebugmask=0x10`（PSR 無効化） | ⚠️ 一部環境（HP Omen 等）で有効だが全環境では効かない |
| vanilla 7.1.6 への切替 | ❌ 同じ上流バグ |
| 7.1.8 への更新 | ✅ 修正予定 |

## BrokenPC での対応

- `hosts/BrokenPC/default.nix`:
  - `boot.kernelPackages = pkgs.linuxPackages_xanmod;`（6.18.41, 7.1.6 のバグなし）
  - `hardware.nvidia.package = pkgs.nvidia_cachyos;` を削除（cachyos 専用ドライバのため）。
    nixpkgs 標準の `boot.kernelPackages.nvidiaPackages.stable`（open モジュール）が自動選択される。
- XanMod を選んだ理由: 低レイテンシー指向（DTM 等のリアルタイム用途に親和）。
- 7.1.8 の修正が上流に入り、cachyos が追従したら、必要に応じて `linuxPackages_cachyos` に戻すことを再検討。

## 未解決・留意点

- 上流での vanilla 7.1.6 再現テストは未実施（issue #959 の報告者は未テスト）。ただし CachyOS 側の
  変更が .5→.6 でほぼ無いため、同じ挙動になると考えられる。
- XanMod（6.18.41）は 6.x 系のため、cachyos と比べメジャーバージョンが古い。暫定運用として妥当。
- NVIDIA dGPU はハードウェア不良（2026-08-02 確認）で offload 無効のため、NVIDIA ドライバ
  バージョン変更（610.57.04 → 595.71.05）の影響は事実上ない。
