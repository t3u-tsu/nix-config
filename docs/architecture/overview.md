# リポジトリ全体アーキテクチャ

関心の分離と責務の明確化に基づき，リポジトリを以下のレイヤに分割する．

## 1. レイヤ構成

| レイヤ / ディレクトリ | 役割と責務 |
| :--- | :--- |
| **`flake/`** | flake-parts サブモジュール群（`hosts`, `lib`, `overlays`, `packages`, `dev`）．Flake エントリポイントの分割． |
| **[`lib/`](../../lib/)** | `mkLib.mkSystem` ヘルパー関数および共通カラーパレット（`palette.nix`）． |
| **[`nixos/`](../../nixos/)** | 全ホスト共有の NixOS システムモジュール群（基盤，セキュリティ，ネットワーク，各種サービス）． |
| **[`home/`](../../home/)** | Home Manager モジュール群（シェル，CLI ツール，GUI アプリケーション，デスクトップ環境）． |
| **[`hosts/`](../../hosts/)** | 各マシン固有のハードウェア定義，ローカルサービス，プラットフォーム固有パッチ． |
| **[`secrets/`](../../secrets/)** | SOPS で暗号化された秘密情報（ホスト固有およびクラスタ共通シークレット）． |
| **[`scripts/`](../../scripts/)** | クラスタ運用・保守スクリプト（Nebula 証明書運用，パスワード生成等）． |
| **[`terraform/`](../../terraform/)** | ConoHa VPS インフラの OpenTofu 定義． |
| **`docs/`** | システム全体の設計仕様，運用ランブック，ハードウェア解説，障害復旧手順（SSOT）． |

---

## 2. モジュール読み込み・評価フロー

各ホストの NixOS 設定が評価されるフロー:

```text
flake.nix
 ├─ imports: flake/lib.nix, flake/overlays.nix, flake/hosts.nix,
 │           flake/packages.nix, flake/dev.nix
 │
 ├─ flake/lib.nix      → flake.lib.mkLib（lib/default.nix を inputs + overlays 付きで import）
 ├─ flake/overlays.nix → flake.overlays.default（nix-minecraft, niri, unstable 等）
 ├─ flake/hosts.nix    → 各ホストの nixosConfigurations を mkLib.mkSystem で定義
 ├─ flake/packages.nix → torii-chan-vps-iso（mkSystem のビルド成果物）
 ├─ flake/dev.nix      → git-hooks の pre-commit hooks と devShells
 │
 └─ lib/default.nix: mkSystem { name, system, username, profile, extraModules }
      └─ nixpkgs.lib.nixosSystem {
           specialArgs = { inputs };        # 全モジュールから inputs を直接参照可能
           modules = [
             { my.user.name = username; }
             sops-nix / home-manager / nix-index-database のモジュール
             home-manager 共通設定（sharedModules: nix-index, sops）
             nixpkgs.overlays
             ../nixos                        # システム共通モジュール群（基盤，セキュリティ，サービス等）
             ../nixos/profiles/${profile}    # プロファイル（desktop, tower-server, gateway 等）
             ../hosts/${name}/default.nix    # ホスト固有エントリ
           ] ++ extraModules;                # ホスト固有の追加モジュール（例: sbc.nix）
         }
```

> [!NOTE]
> 外部モジュール（`nix-minecraft`，`noctalia-greeter`，`zen-browser`，`noctalia`）は，利用先のモジュール（`nixos/services/` や `home/desktop/`）で直接インポートし，スコープを局所化する．

---

## 3. ホストからモジュールへの展開

`mkLib.mkSystem` により，プロファイル，ホスト固有定義，および共通モジュールを合成する．

```text
mkLib.mkSystem によるモジュール合成
 ├─ nixos/                    # システム共通モジュール群（直接注入）
 │   ├─ base, core, security (SOPS), dev-tools, environment, hardware
 │   ├─ networking, services, virtualisation
 │   └─ ../home/              # Home Manager 共通設定
 │
 ├─ nixos/profiles/<profile>/ # ロール別ベースライン設定
 │   ├─ desktop/              # GUI環境（niri, greetd, fonts, gaming），home/desktop
 │   ├─ tower-server/         # 常時稼働サーバー共通基盤（boot, security, ssh）
 │   ├─ gateway/              # ルータ・ゲートウェイロール（torii-chan）
 │   └─ sbc/                  # 低スペックSBC制約緩和（sbc.nix 経由で適用）
 │
 ├─ hosts/<name>/default.nix  # ホスト固有定義
 │   ├─ ./hardware.nix        # ハードウェア固有設定（fileSystems, swap, カーネル）
 │   └─ ./services/           # ホスト固有サービス（該当する場合）
 │
 └─ extraModules              # ホスト固有の追加モジュール（例: sbc.nix, fs-hdd.nix）
```

---

## 4. モジュール評価順序と優先度制御

### 構成モジュールの注入順序
`modules` リストは `../nixos` → `profile` → `hosts/<name>/default.nix` → `extraModules` の順序で合成する．プロファイルで基本設定を与え，ホスト固有定義で具体値を確定し，`extraModules` でプラットフォーム差分を注入する．

### 優先度制御（Priority System）
スカラー値オプションの競合時はエラー（conflicting definitions）となる．プロファイル側の初期値には `lib.mkDefault`（優先度 1000），ホストやモジュールからの強制適用には `lib.mkForce`（優先度 50）を使用する．

### コレクション型オプションの結合
`environment.systemPackages` などのリスト型や属性セット型オプションは，モジュール間で自動的にマージ・結合される．

---

## 関連ドキュメント
- [目次（設計・運用ドキュメント）](../README.md)
- [ネットワークアーキテクチャ](network-topology.md)
- [Flake とモジュール設計原則](flake-and-modules.md)
- [新規ホスト追加手順](../operations/adding-a-host.md)
