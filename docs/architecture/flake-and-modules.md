# Flake とモジュール設計原則

本ドキュメントは，本リポジトリにおける Nix Flake のモジュール構成，`mkSystem` ビルダーの仕組み，およびカスタムオプション（`my.*`）の命名規則・設計原則を解説する．

---

## 1. Flake 構成と分割 (`flake/`)

リポジトリ直下の `flake.nix` は [flake-parts](https://github.com/hercules-ci/flake-parts) を採用し，責務ごとに分割されたサブモジュールを読み込むのみに留めている．

- **`flake/hosts.nix`**: 各ホストの `nixosConfigurations` を定義する．
- **`flake/lib.nix`**: `mkLib` を公開し，flake inputs と overlays を合成したカスタムライブラリを提供する．
- **`flake/overlays.nix`**: nixpkgs のオーバーレイ群（`nix-minecraft`, `niri`, `ghostty`, `llama-cpp`, `unstable` 等）を合成・定義する．
- **`flake/packages.nix`**: カスタムビルド成果物（例: `torii-chan-vps-iso`）を `packages.${system}` に公開する．
- **`flake/dev.nix`**: pre-commit hooks（`git-hooks.nix`）および開発シェル（`devShells`）を提供する．

---

## 2. システムビルダー (`lib/mkSystem`)

すべてのホストは `lib/default.nix` に定義された `mkSystem` 関数を経由してインスタンス化される．

```nix
mkLib.mkSystem {
  name = "hostname";              # ホスト名（必須）
  system = "x86_64-linux";        # アーキテクチャ（必須: x86_64-linux / aarch64-linux）
  username = "t3u";               # プライマリユーザー名（必須）
  profile = "desktop";            # プロファイル名（必須: desktop / tower-server / gateway / sbc）
  extraModules = [ ... ];         # ホスト固有の追加モジュール（任意）
}
```

### 内部で自動注入される共通機能
- **`specialArgs.inputs`**: 全モジュール内から `inputs.<name>` を直接参照可能．
- **`sops-nix` / `home-manager`**: 基盤システムとして自動統合．
- **プロファイル自動適用**: `nixos/profiles/${profile}` が自動的に評価順の先頭に配置される．
- **共通オーバーレイ**: `nixpkgs.overlays` が全ホストに均一に適用される．

---

## 3. カスタムオプション (`my.*`) の命名規則

本リポジトリでは，設定のモジュール性と関心の分離を保つため，独自オプションに `my.` プレフィックスを付与している．

| オプション階層 | 配置場所 | 役割と具体例 |
| :--- | :--- | :--- |
| **`my.user.name`** | `nixos/base/user.nix` | プライマリユーザー名の定義（全モジュールで参照） |
| **`my.services.<name>`** | `nixos/services/` | システムレベルの共有サービス（例: `my.services.minecraft`, `my.services.gateway`） |
| **`my.packages.<category>`** | `nixos/environment/` | 目的別の共通パッケージ群（例: `my.packages.gui`, `my.packages.development`） |
| **`my.hardware.<name>`** | `nixos/hardware/` | ハードウェア機能の抽象化（例: `my.hardware.bluetooth`, `my.hardware.audio`） |
| **`my.home.desktop.<category>.<name>`** | `home/desktop/` | デスクトップ環境のユーザー設定（例: `my.home.desktop.terminals.ghostty`） |

### オプション設計の原則
1. **デフォルト無効**: 各モジュールは `enable = mkEnableOption "..."` を持ち，明示的に要求されない限り評価・適用されない．
2. **自己完結性**: サービスを有効化した際，必要なファイアウォール開放，ユーザー作成，SOPS シークレット配線，systemd ユニット定義が当該モジュール内で完結すること．
3. **トップレベルキーの集約**: statix の規約に従い，同一属性セットは分割せず 1 つのブロックで定義する．

---

## 4. パッケージ導入方式の選定基準

NixOS 環境に新しいパッケージやツールを導入する際は，以下の優先順位と基準に従う．

1. **`nixpkgs` (stable / unstable)**:
   - 最優先．標準リポジトリにパッケージが存在する場合は，`pkgs.<name>` または `pkgs.unstable.<name>` を使用する．
2. **`nvfetcher` (`_sources/`)**:
   - nixpkgs に存在しない，または最新リリースの追従が必要な単体バイナリ・Git リポジトリ．
   - 日次自動更新ワークフロー（`auto-update.yml`）で自動的にハッシュ値が更新される．
3. **Flake inputs (`flake.nix`)**:
   - 上流プロジェクトが Flake として NixOS モジュールやオーバーレイを提供している場合（例: `niri`, `nix-minecraft`）．
   - キャッシュの最適化のため，可能な限り `inputs.<name>.inputs.nixpkgs.follows = "nixpkgs"` を指定する（詳細は [`../operations/maintenance.md`](../operations/maintenance.md) 参照）．

---

## 関連ドキュメント
- [リポジトリ全体アーキテクチャ](overview.md)
- [モジュール配置ガイド](../../.agents/skills/editing-guide/SKILL.md)
- [新ホスト追加手順](../operations/adding-a-host.md)
