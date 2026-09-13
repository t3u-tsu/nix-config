# リポジトリ設計リファレンス

この文書は，リポジトリの層構成と，ドキュメント・モジュールがどのように参照され評価されるかを説明する．

## ドキュメントの参照構造

```text
README.md                 リポジトリの全体像と各層への入口
 ├─ nixos/README.md       システムモジュールの分類と配置ルール
 ├─ home/README.md        home-manager モジュールの分類と配置ルール
 ├─ hosts/README.md       ホストの構成と追加手順
 ├─ secrets/README.md     SOPS の鍵モデルと編集手順
 ├─ scripts/README.md     運用スクリプト
 └─ terraform/README.md   ConoHa VPS インフラ
docs/architecture.md      この文書（層構成と読み込みの説明）
.codewhale/skills/        エージェント向けの手順（AGENTS.md から参照）
```

各 README は自分の層の責務と配置ルールを説明し，詳細は下位の README かコードに委ねる．

## 層構成

- `flake/`: flake-parts のモジュール（hosts, lib, overlays, packages, dev）．
- `lib/`: mkSystem．profile とホストを合成して nixosSystem を作る．
- `nixos/`: 全ホスト共通のシステムモジュール．
- `home/`: home-manager モジュール．shell / programs は全ホスト，desktop は desktop プロファイルのみ．
- `hosts/`: マシン固有の定義とプラットフォーム層．
- `secrets/`・`scripts/`・`terraform/`: 運用側．

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
     ├─ gateway/              # nixos/services/gateway のロールを有効化
     └─ sbc/                  # 低メモリ SBC（sandbox 無効化等．torii-chan/sbc.nix 経由）
```

## モジュール評価順序

- modules リストは `profile → hosts/<name>/default.nix → extraModules` の順で評価され，後の設定が前を上書きできる．
- `environment.systemPackages` のようなリスト型オプションは評価順に連結される．モジュール構成を変えると順序が変わり drv も変わる（パッケージ集合が同じなら実害は通常ない）．
- 優先度を明示的に制御する場合は `mkForce` / `mkDefault` / `mkOrder` を使用する．
