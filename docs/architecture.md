# リポジトリ設計リファレンス

## ディレクトリ構成

- `nixos/base/`: システム共通基盤（User, Nix, Time）
- `nixos/core/`: OS 基本動作（i18n）
- `nixos/security/`: 機密管理（SOPS）
- `nixos/networking/`: ネットワーク（Nebula, hosts）
- `nixos/environment/`: システムパッケージ
- `nixos/hardware/`: ハードウェア固有設定
- `nixos/dev-tools/`: 開発ツール（WCH-LinkE udev, Ventoy）
- `nixos/profiles/`: 役割別プロファイル（desktop / sbc / tower-server / gateway）
- `nixos/services/`: システムサービス
- `nixos/virtualisation/`: 仮想化（distrobox, microvm）
- `home/shell/`: シェル環境（Zsh, Pure, Atuin）
- `home/programs/`: 共通ワークステーションツール（CLI ツール, Git, SSH）
- `home/desktop/`: GUI アプリ, WM（Niri/Noctalia）, dev-tools（desktop 限定）
- `hosts/`: マシン固有の定義（例: torii-chan は SBC と VPS で役割を共有）
- `flake/`: フレーク定義（lib, overlays, hosts, packages, dev）
- `lib/`: システムビルダー（mkSystem）
- `secrets/`: SOPS による機密情報管理
- `terraform/`: ConoHa VPS インフラ管理（OpenTofu）

## モジュール読み込みフロー

```text
flake.nix
 ├─ imports: flake/lib.nix, flake/overlays.nix, flake/hosts.nix,
 │           flake/packages.nix, flake/dev.nix
 │
 ├─ flake/lib.nix      → flake.lib.mkLib（lib/default.nix を inputs + overlays 付きで import）
 ├─ flake/overlays.nix → flake.overlays.default（nix-minecraft, niri, ghostty, unstable, U-Boot 等）
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
             ../nixos/profiles/${profile}    # profile は必須（mkSystem が自動適用）
             ../hosts/${name}/default.nix    # ホスト固有エントリ
           ] ++ extraModules;                # ホスト固有の追加モジュール（例: sbc.nix）
         }
```

## ホストからモジュールへの展開

典型的なホストの例（torii-chan は `./hardware.nix`・`./services` を持たず，`flake/hosts.nix` の `extraModules` で `sbc.nix`/`vps.nix` を import する）:

```text
hosts/<name>/default.nix
 ├─ ./hardware.nix            # ハードウェア固有設定
 ├─ ./services                # ホスト固有サービス
 ├─ ../../nixos               # nixos/default.nix が一括 import:
 │                             base（user/nix/time）, core（i18n）, security（SOPS）,
 │                             networking（Nebula/hosts）, environment（パッケージ群）,
 │                             hardware, dev-tools, services, virtualisation, ../home
 │   └─ home/default.nix      # home-manager.users.<user>（sops.nix, shell/, programs/）
 └─ ../../nixos/profiles/<profile>（mkSystem が自動適用．hosts/<name>/ より前に評価）
     ├─ desktop/              # services/desktop（niri, greetd, fonts, gaming 等）と
     │                         nyx-overlay を有効化し，home/desktop を home-manager に import
     ├─ tower-server/         # boot, security, ssh（タワーサーバー共通）
     ├─ gateway/              # torii-chan ロール（Nebula + DDNS + Minecraft forward）
     └─ sbc/                  # 低メモリ SBC（sandbox 無効化等．torii-chan/sbc.nix 経由）
```

## モジュール評価順序

- modules リストは `profile → hosts/<name>/default.nix → extraModules` の順で評価され，後の設定が前を上書きできる．
- `environment.systemPackages` のようなリスト型オプションは評価順に連結される．モジュール構成を変えると順序が変わり drv も変わる（パッケージ集合が同じなら実害は通常ない）．
- 優先度を明示的に制御する場合は `mkForce` / `mkDefault` / `mkOrder` を使用する．
