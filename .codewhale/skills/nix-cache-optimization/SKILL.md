---
name: nix-cache-optimization
description: 外部 Flake パッケージ導入時の follows 制約と，extra-substituters の priority 設定について．ビルドがキャッシュから取得できず重いコンパイルが走るときに参照する．
---

# Nix キャッシュ最適化

外部 Flake パッケージの導入やバイナリキャッシュの設定変更時に使う知見．

## flake 入力の follows 制約

`ghostty` のような重いコンパイルを要する外部 Flake パッケージを導入する際，`inputs.nixpkgs.follows = "nixpkgs";` でローカルの nixpkgs に追従させると，キャッシュ側でビルドされたパッケージのハッシュ値と不一致になり，バイナリがダウンロードできない．

キャッシュのビルド済みバイナリを確実に利用するには，該当パッケージが求めるオリジナルの nixpkgs 依存関係のまま動かす．ただし follows を外すと不要な nixpkgs インスタンスの複製（ディスク消費）が発生する可能性があるため，`dry-build` で「本当に重たい Zig/C コンパイルが走るのか，それとも軽量な Nix ラッパーのみのビルドなのか」を検証し，follows 制約の有無を判断する．

## extra-substituters の priority 設計

`nixos/base/nix.nix` の `extra-substituters` に登録するキャッシュ URL には `?priority=` パラメータを付与して評価の優先順位を制御する．

- **専門枠 (priority=30)**: `ghostty`, `niri` など（公式の `40` より先にヒットさせたいもの）
- **コミュニティ枠 (priority=41)**: `nix-community`（公式の直後）
- **特定専門枠 (priority=45)**: `cuda-maintainers`, `nix-gaming`
- **魔改造枠 (priority=50)**: `chaotic-nyx`（他と競合するリスクがあるため最後尾）

`extra-substituters` の並び順と `extra-trusted-public-keys` の公開鍵の並び順は完全に一致させる．

`extra-substituters` / `extra-trusted-public-keys` は必ず `nixos/base/nix.nix`（全ホスト共通）で管理する．外部フレークの提供する `nixConfig` を `nix.settings = <flake>.nixConfig;` で直接参照するのは避け，同値の内容（substituter URL と trusted-public-keys）を base/nix.nix に手動で追加する．優先度・並び順も base/nix.nix で統一する．
