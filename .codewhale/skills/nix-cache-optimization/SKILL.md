---
name: nix-cache-optimization
description: 外部 Flake パッケージ導入時の follows 制約と，extra-substituters の priority 設定について．外部 Flake や extra-substituters 等を追加するときや，ビルドがキャッシュから取得できず重いコンパイルが走るときに参照する．
---

# Nix キャッシュ最適化

## flake 入力の follows 制約

`ghostty` のような重いコンパイルを要する外部 Flake パッケージは，`inputs.nixpkgs.follows = "nixpkgs";` でローカル nixpkgs に追従させるとキャッシュ側のビルドとハッシュが一致せず，バイナリを取得できない．

キャッシュのビルド済みバイナリを使うには，そのパッケージが想定する nixpkgs 依存のまま動かす．ただし follows を外すと不要な nixpkgs インスタンスが複製されディスクを消費するため，`dry-build` で「重い Zig/C コンパイルが走るのか，軽量なラッパーだけで済むのか」を確認してから判断する．

## extra-substituters の priority

キャッシュ URL には `?priority=` を付け，`nixos/base/nix.nix` で管理する．

- **専門枠 (30)**: `ghostty`, `niri`, `noctalia`（公式の `40` より先にヒットさせたいもの）
- **コミュニティ枠 (41)**: `nix-community`（公式の直後）
- **特定専門枠 (45)**: `cuda-maintainers`, `nix-gaming`, `ezkea`
- **魔改造枠 (50)**: `chaotic-nyx`（他と競合するリスクがあるため最後尾）

`extra-substituters` と `extra-trusted-public-keys` は並び順を完全に一致させる．どちらも必ず `nixos/base/nix.nix`（全ホスト共通）で管理し，外部フレークの `nixConfig` を `nix.settings = <flake>.nixConfig;` で直接参照しない．同値の substituter URL と trusted-public-keys を手動で base/nix.nix に追加し，優先度と並び順もそこで統一する．
