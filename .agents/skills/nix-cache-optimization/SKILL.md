---
name: nix-cache-optimization
description: 外部 Flake パッケージ導入時の follows 制約と，extra-substituters の priority 設定．外部 Flake 追加時やビルドキャッシュ未適用の調査時に参照する．
---

# Nix キャッシュ最適化

## Flake 入力の follows 制約

`ghostty` のような重いコンパイルを伴う外部 Flake パッケージは，`inputs.nixpkgs.follows = "nixpkgs";` でローカルの nixpkgs に追従させると，キャッシュ側のビルドとハッシュが一致せずバイナリキャッシュを取得できなくなる．

キャッシュのビルド済みバイナリを使用するには，パッケージ本来の依存 nixpkgs のまま評価させる．follows を外すと別バージョンの nixpkgs が評価空間に複製されてディスクを消費するため，`nix build --dry-run` 等でコンパイル負荷 (重い Zig/C コンパイルか軽量なラッパー構築か)を確認して判断する．

## extra-substituters の priority

キャッシュ URL には `?priority=` パラメータを付与し，全ホスト共通の [nixos/base/nix.nix](../../../nixos/base/nix.nix) で一元管理する．

| priority | キャッシュ区分 | 対象キャッシュ |
| :--- | :--- | :--- |
| `30` | 個別ツール枠 (公式キャッシュの `40` より優先) | `noctalia` (`noctalia.cachix.org`) |
| `41` | コミュニティ枠 (公式キャッシュの直後) | `nix-community` (`nix-community.cachix.org`) |
| `42` | AI エージェント・ツール枠 | `llm-agents.nix` (`cache.numtide.com`) |
| `45` | 特定用途枠 | `ezkea` (`ezkea.cachix.org`, aagl ゲームランチャー) |

`extra-substituters` と `extra-trusted-public-keys` のリスト順序は完全に一致させる．[nixos/base/nix.nix](../../../nixos/base/nix.nix) で一括管理し，外部 Flake の `nixConfig` (`nix.settings = <flake>.nixConfig;`)は参照しない．substituter URL と trusted-public-keys を [nixos/base/nix.nix](../../../nixos/base/nix.nix) に明示し，優先度と順序を揃える．
