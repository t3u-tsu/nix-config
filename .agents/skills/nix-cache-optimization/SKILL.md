---
name: nix-cache-optimization
description: 外部 Flake パッケージ導入時の follows 制約と，extra-substituters の priority 設定．外部 Flake 追加時やビルドキャッシュ未適用の調査時に参照する．
---

# Nix キャッシュ最適化

## Flake 入力の follows 制約

`ghostty` のような重いコンパイルを伴う外部 Flake パッケージは，`inputs.nixpkgs.follows = "nixpkgs";` でローカルの nixpkgs に追従させると，キャッシュ側のビルドとハッシュが一致せずバイナリキャッシュを取得できなくなる．

キャッシュのビルド済みバイナリを使用するには，パッケージが元々依存している nixpkgs のまま評価させる．ただし follows を外すと別バージョンの nixpkgs が評価空間に複製されてディスクを消費するため，`nix build --dry-run` 等で「重い Zig/C コンパイルが走るか，軽量なラッパー構築だけで済むか」を確認して判断する．

## extra-substituters の priority

キャッシュ URL には `?priority=` パラメータを付与し，全ホスト共通の `nixos/base/nix.nix` で一元管理する．

- **個別ツール枠 (30)**: `niri`, `noctalia`（公式キャッシュの `40` より優先）
- **コミュニティ枠 (41)**: `nix-community`（公式キャッシュの直後）
- **特定用途枠 (45)**: `ezkea`（aagl ゲームランチャー）

`extra-substituters` と `extra-trusted-public-keys` のリスト順序は完全に一致させる．これらは必ず `nixos/base/nix.nix` で一括管理し，外部 Flake の `nixConfig` を `nix.settings = <flake>.nixConfig;` のように直接参照してはならない（手動で substituter URL と trusted-public-keys を `nixos/base/nix.nix` に明示し，優先度と順序を揃える）．
