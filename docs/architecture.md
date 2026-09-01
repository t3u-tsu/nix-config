# リポジトリ設計リファレンス

本リポジトリの構造とモジュール評価の仕組み

## 構成ディレクトリ構造

- `nixos/base/`: システム共通インフラ基盤（User, Nix, Time）
- `nixos/core/`: OS核心動作環境（i18n）
- `nixos/security/`: セキュリティ・機密管理（SOPS）
- `nixos/networking/`: ネットワーク・VPN（Nebula, Hosts）
- `nixos/environment/`: システムパッケージ
- `nixos/hardware/`: ハードウェア固有設定
- `nixos/profiles/`: 役割別プロファイル（desktop / sbc / tower-server / gateway）
- `nixos/services/`: システムサービス
- `nixos/virtualisation/`: 仮想化（distrobox, microvm）
- `home/shell/`: ユーザーシェル環境（Zsh, Starship, Atuin）
- `home/programs/`: 共通ワークステーションツール（CLIツール, Git, SSH）
- `home/desktop/`: GUI アプリ，WM (Niri/Noctalia)，dev-tools（開発ツール，desktop 限定）
- `hosts/`: マシン固有の定義（例: torii-chan は SBC + VPS フェイルオーバーを共有）
- `flake/`: フレーク定義（hosts, overlays）
- `lib/`: システムビルダー・ヘルパー（mkSystem）
- `secrets/`: SOPS による機密情報管理
- `terraform/`: ConoHa VPS インフラ管理（OpenTofu）

## モジュール読み込みフロー

```text
flake.nix
 ├─ imports: flake/lib.nix, flake/overlays.nix, flake/hosts.nix, flake/packages.nix
 │
 ├─ flake/lib.nix      → flake.lib.mkLib を定義（lib/default.nix を inputs + overlays 付きで import）
 ├─ flake/overlays.nix → flake.overlays.default（nix-minecraft, niri, ghostty, unstable, U-Boot 等）
 ├─ flake/hosts.nix    → 各ホストの nixosConfigurations を mkLib.mkSystem で定義
 ├─ flake/packages.nix → torii-chan-vps-iso（mkSystem のビルド成果物）
 │
 └─ lib/default.nix: mkSystem { name, system, username, profile, extraModules }
      └─ nixpkgs.lib.nixosSystem {
           specialArgs = { inputs };        # 全モジュールから inputs を直接参照可能
           modules = [
             { my.user.name = username; }    # ユーザー名の伝達
             sops-nix / nix-minecraft / home-manager /
             nix-index-database / noctalia-greeter のモジュール
             home-manager 共通設定（sharedModules: nix-index, zen-browser, sops, noctalia）
             nixpkgs.overlays
             ../nixos/profiles/${profile}    # profile は必須（mkSystem が自動適用）
             ../hosts/${name}/default.nix    # ホスト固有エントリ
           ] ++ extraModules;                # ホスト固有の追加モジュール（例: sbc.nix）
         }
```

## ホストからモジュールへの展開

```text
hosts/<name>/default.nix
 ├─ ./hardware.nix            # ハードウェア固有設定
 ├─ ./services                # ホスト固有サービス
 ├─ ../../nixos               # nixos/default.nix が一括 import:
 │                             base（user/nix/time）, core（i18n）, security（SOPS）,
 │                             networking（Nebula/hosts）, environment（パッケージ群）,
 │                             hardware, services, virtualisation, ../home
 │   └─ home/default.nix      # home-manager.users.<user>
 │                             imports: shell/, programs/
 │                             ※ desktop 系はここでは読み込まれない
 └─ ../../nixos/profiles/<profile>（mkSystem が自動適用．hosts/<name>/ より前に評価）
     ├─ desktop/              # services/desktop, fonts, nyx-overlay
     │                         + home/desktop を home-manager に import（desktop 専用）
     ├─ tower-server/         # boot, security, ssh（タワーサーバー共通）
     ├─ gateway/              # torii-chan ロール（Nebula + DDNS + Minecraft forward）
     └─ sbc/                  # 低メモリ SBC（sandbox 無効化等．torii-chan/sbc.nix 経由）
```

## モジュール評価順序

- mkSystem の modules リストは `profile → hosts/<name>/default.nix → extraModules` の順で評価される．
- ホスト固有設定（hosts/<name>）がプロファイルの設定を上書きできる．
- `environment.systemPackages` のようなリスト型オプションはマージ順に連結されるため，モジュール構成を変えると順序が変わり drv が変わる（パッケージ集合は不変なので実害は通常ない）．
- 優先度を明示的に制御したい場合は `mkForce` / `mkDefault` / `mkOrder` を使用する．
