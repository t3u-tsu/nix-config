# リポジトリ全体アーキテクチャ

本ドキュメントは，リポジトリのレイヤ構成，ファイル配置，およびモジュールの評価フローを説明する．

---

## 1. レイヤ構成

リポジトリは責務に応じて明確に分離されている．

| レイヤ / ディレクトリ | 役割と責務 |
| :--- | :--- |
| **`flake/`** | flake-parts モジュール群（`hosts`, `lib`, `overlays`, `packages`, `dev`）．Flake エントリポイントの分割． |
| **[`lib/`](../../lib/)** | `mkLib.mkSystem` ヘルパー関数および共通カラーパレット（`palette.nix`）． |
| **[`nixos/`](../../nixos/)** | 全ホストで共有される NixOS システムモジュール群（基盤，セキュリティ，ネットワーク，各種サービス）． |
| **[`home/`](../../home/)** | Home Manager モジュール群（シェル，CLI ツール，GUI アプリケーション，デスクトップ環境）． |
| **[`hosts/`](../../hosts/)** | マシン固有のハードウェア定義，ローカルサービス，プラットフォーム固有パッチ． |
| **[`secrets/`](../../secrets/)** | SOPS で暗号化された秘密情報（ホスト固有および共通シークレット）． |
| **[`scripts/`](../../scripts/)** | クラスタ運用・保守スクリプト（Nebula 証明書，パスワード生成等）． |
| **[`terraform/`](../../terraform/)** | ConoHa VPS インフラの OpenTofu 定義． |
| **`docs/`** | システム全体の設計仕様，運用手順，ハードウェア解説，トラブルシューティング（SSOT）． |

---

## 2. モジュール読み込み・評価フロー

```text
flake.nix
 ├─ imports: flake/lib.nix, flake/overlays.nix, flake/hosts.nix,
 │           flake/packages.nix, flake/dev.nix
 │
 ├─ flake/lib.nix      → flake.lib.mkLib（lib/default.nix を inputs + overlays 付きで import）
 ├─ flake/overlays.nix → flake.overlays.default（nix-minecraft, niri, ghostty, llama-cpp, unstable 等）
 ├─ flake/hosts.nix    → 各ホストの nixosConfigurations を mkLib.mkSystem で定義
 ├─ flake/packages.nix → torii-chan-vps-iso（mkSystem のビルド成果物）
 ├─ flake/dev.nix      → git-hooks の pre-commit hooks と devShells
 │
 └─ lib/default.nix: mkSystem { name, system, username, profile, extraModules }
      └─ nixpkgs.lib.nixosSystem {
           specialArgs = { inputs };        # 全モジュールから inputs を直接参照可能
           modules = [
             { my.user.name = username; }
             sops-nix / nix-minecraft / home-manager /
             nix-index-database / noctalia-greeter のモジュール
             home-manager 共通設定（sharedModules: nix-index, zen-browser, sops, noctalia）
             nixpkgs.overlays
             ../nixos/profiles/${profile}    # プロファイル（desktop, tower-server, gateway 等）
             ../hosts/${name}/default.nix    # ホスト固有エントリ
           ] ++ extraModules;                # ホスト固有の追加モジュール（例: sbc.nix）
         }
```

---

## 3. ホストからモジュールへの展開

各ホスト（`hosts/<name>/default.nix`）は，必要なハードウェア設定やローカルサービスを import しつつ，共通モジュール層を展開する．

```text
hosts/<name>/default.nix
 ├─ ./hardware.nix            # ハードウェア固有設定（fileSystems, swap, カーネルモジュール）
 ├─ ./services/               # ホスト固有サービス（該当する場合）
 ├─ ../../nixos/              # nixos/default.nix が一括 import:
 │                             base（user, nix, time, private-config）
 │                             core（i18n, fonts）
 │                             security（SOPS）
 │                             networking（Nebula, local-network）
 │                             environment（基本パッケージ群）
 │                             hardware, dev-tools, services, virtualisation
 │                             ../../home/default.nix（Home Manager 共通展開）
 └─ ../../nixos/profiles/<profile>/
     ├─ desktop/              # services/desktop（niri, greetd, fonts, gaming 等）を有効化し
     │                         nyx-overlay を適用，home/desktop を import
     ├─ tower-server/         # boot, security, ssh（タワーサーバー共通基盤）
     ├─ gateway/              # nixos/services/gateway のルータ・ゲートウェイロールを有効化
     └─ sbc/                  # 低メモリ SBC 向け制約緩和（sandbox 無効化等．sbc.nix 経由）
```

---

## 4. モジュール評価順序と優先度制御

1. **評価順序**:
   - `modules` リストは `profile → hosts/<name>/default.nix → extraModules` の順序でリストに配置される．
   - モジュール内の設定値は，デフォルトでは後から評価されたものが前を上書きする．
2. **リスト型オプションの結合**:
   - `environment.systemPackages` などのリスト型オプションは評価順に連結される．
3. **明示的優先度制御**:
   - プラットフォーム層やホスト固有の特殊要件で競合が発生する場合，`lib.mkForce`，`lib.mkDefault`，`lib.mkOrder` を使用して優先度を明示的に制御する．

---

## 関連ドキュメント
- [ネットワークアーキテクチャ](network-topology.md)
- [Flake & モジュール設計原則](flake-and-modules.md)
- [新ホスト追加手順](../operations/adding-a-host.md)
