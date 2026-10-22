# Flake とモジュール設計原則

Flake のモジュール構成，`mkSystem` ビルダーの仕組み，およびカスタムオプション（`my.*`）の命名規則・設計原則を定義する．

## 1. Flake 構成と分割 (`flake/`)

`flake.nix` は [flake-parts](https://github.com/hercules-ci/flake-parts) を採用し，責務ごとにサブモジュールを分割して読み込む．

- `flake/hosts.nix`: 各ホストの `nixosConfigurations` を定義する．
- `flake/lib.nix`: `mkLib` を公開し，flake inputs と overlays を合成したライブラリを提供する．
- `flake/overlays.nix`: nixpkgs のオーバーレイ群（`nix-minecraft`，`niri`，`unstable` 等）と，YSH スクリプト生成関数（`writeYsh`，`writeYshBin`，`writeYshApplication`）を定義する．
- `flake/packages.nix`: カスタムビルド成果物（例: `torii-chan-vps-iso`）を `packages.${system}` に公開する．
- `flake/dev.nix`: pre-commit hooks（`git-hooks.nix`）および開発シェル（`devShells`）を提供する．

---

## 2. システムビルダー (`mkSystem`)

全ホストは `lib/default.nix` に定義された `mkSystem` 関数を経由してインスタンス化する．

```nix
mkLib.mkSystem {
  name = "hostname";              # ホスト名（必須）
  system = "x86_64-linux";        # アーキテクチャ（必須: x86_64-linux / aarch64-linux）
  username = "t3u";               # プライマリユーザー名（任意，既定値: "t3u"）
  profile = "desktop";            # プロファイル名（必須: desktop / tower-server / gateway / sbc）
  extraModules = [ ... ];         # ホスト固有の追加モジュール（任意）
}
```

### 自動注入される共通機能
- `specialArgs.inputs` による全モジュールからの `inputs.<name>` 直接参照
- `sops-nix` および `home-manager` の基盤統合
- プロファイル（`nixos/profiles/${profile}`）のホスト個別設定直前への自動配置
- `nixpkgs.overlays` の全ホスト適用

---

## 3. カスタムオプション (`my.*`) の命名規則

設定のモジュール性と関心の分離を保つため，独自オプションに `my.` プレフィックスを付与する．

| オプション階層 | 配置場所 | 役割と具体例 |
| :--- | :--- | :--- |
| **`my.user.name`** | `nixos/base/user.nix` | プライマリユーザー名の定義（全モジュールで参照） |
| **`my.networking.<name>`** | `nixos/networking/` | ネットワークおよびメッシュ機能（例: `my.networking.nebula`） |
| **`my.services.<name>`** | `nixos/services/` | システムレベルの共有サービス（例: `my.services.minecraft`，`my.services.gateway`） |
| **`my.packages.<category>`** | `nixos/environment/` | 目的別の共通パッケージ群（例: `my.packages.core`，`my.packages.network-tools`） |
| **`my.hardware.<name>`** | `nixos/hardware/` | ハードウェア機能の抽象化（例: `my.hardware.nvidia`，`my.hardware.pc-tools`） |
| **`my.home.desktop.<category>.<name>`** | `home/desktop/` | デスクトップ環境のユーザー設定（例: `my.home.desktop.dev-tools.ghostty`） |

### オプション設計の原則
- デフォルト無効: 各モジュールは `enable = mkEnableOption "..."` を持ち，`true` を明示指定した場合に適用する．
- 自己完結性: サービス有効化時に必要なファイアウォール開放，ユーザー作成，SOPS シークレット配線，systemd ユニット定義を当該モジュール内で完結させる．
- トップレベルキーの集約: statix の規約に従い，同一属性セットを 1 つのブロックで定義する．

---

## 4. パッケージ導入方式の選定基準

優先度順に選定する:

1. **nixpkgs (stable / unstable)**: 標準リポジトリにパッケージが存在する場合に最優先で採用する（`pkgs.<name>` または `pkgs.unstable.<name>`）．
2. **nvfetcher (`_sources/`)**: nixpkgs に存在しない，または最新リリースの追従が必要な単体バイナリや Git リポジトリ．日次自動更新ワークフロー（`auto-update.yml`）でハッシュ値を更新する．
3. **Flake inputs (`flake.nix`)**: 上流プロジェクトが Flake として NixOS モジュールやオーバーレイを提供している場合（例: `niri`，`nix-minecraft`）．コンパイル負荷の高い外部 Flake パッケージは，`follows = "nixpkgs"` によるバイナリキャッシュ不整合と nixpkgs インスタンス複製のトレードオフを考慮して判断する（詳細は `nix-cache-optimization` スキル参照）．

---

## 関連ドキュメント
- [目次（設計・運用ドキュメント）](../README.md)
- [リポジトリ全体アーキテクチャ](overview.md)
- [モジュール配置ガイド](../../.agents/skills/editing-guide/SKILL.md)
- [新規ホスト追加手順](../operations/adding-a-host.md)
- [日常保守 & ライフサイクル管理](../operations/maintenance.md)
