# NixOS 設定構築 - 運用・開発ガイド

このドキュメントは，本リポジトリの設計思想，開発ワークフロー，および作業履歴を管理するためのものです．

---

## プロジェクト概要

本リポジトリは，宣言的で高度にカスタマイズされたデスクトップ環境及びサーバー群の構築を目指しています．

---

## 開発ワークフロー

### 1. 作業の基本ルール
- **ブランチ戦略**: 直接 `main` にコミットせず，**作業を開始する前（いかなるファイル編集前）に必ず** ブランチを作成・切り替えてください．`main` 上でファイルを編集してからブランチを切る行為は禁止します．ただし，GitHub Actions の自動更新ワークフロー（`.github/workflows/auto-update.yml`）が `nvfetcher` と `flake.lock` の更新を `main` へ直接コミットするのは意図的な例外です（README の CI/CD セクション参照）．
- **ブランチ命名規約**: Conventional Commits の型に揃え，`feat/<名前>`・`fix/<名前>`・`refactor/<名前>`・`docs/<名前>`・`chore/<名前>` のいずれかを使用します（必要ならばこの5種を超えてもよい）．`.github/workflows/nix-check.yml` の push 対象と `flake.nix` の `pre-commit` hooks（convco による Conventional Commits 検証）と整合するよう，新たな型を追加する場合は**三方同時に更新**してください．
- **対応言語**: ユーザーへの報告，相談はすべて **日本語** で行います．
- **コード・コミットの言語**: コード内コメントおよびコミットメッセージは **英語** で記述します（日本語のコメント・コミットメッセージは書かない）．ドキュメントも `AGENTS.md` を除いて英語を基本とします．
- **コメント方針**: コード内コメントは，基本的に付けない．コードの意図を読めず困る場合のみ，1〜2行の最小限の説明に留める．長い説明コメント，外部フレーク・wiki 由来の説明の貼り付け，見出し目的のコメントは付けない．関連作業の範囲で長すぎる既存コメントを見かけたら削除する．
- **バイリンガル対応 (Bilingual Sync)**: プロジェクトルートの `README.md` および `README.ja.md` は，必ず英語と日本語の両方を同時に同期して更新してください．サブディレクトリの `README.md` は英語のみで管理し，日英の重複管理は行いません．
- **ドキュメント優先**: 変更の際は `TODO.md` や `README.md` との整合性を確認してください．
- **コミット方針**: 適切なコミットメッセージ（Conventional Commits 準拠など）と共にコミットし，変更内容の詳細はコミットメッセージおよび PR (Pull Request) の説明に詳しく記述してください．
- **ユーザー承認の義務化**: `main` へのマージ，リモートの `main` へのプッシュ，および `nixos-rebuild switch` の適用を行う際は，必ず実行前にユーザーへ明示的に確認し，承認を得てから進めてください．
- **nix run及びnix shellの利用**: 本環境には `python3` を始め，ほとんどのパッケージがインストールされていないため，必要なパッケージを実行する際は `nix run` 及び `nix shell` を利用してください．

### 2. 変更・適用手順
1.  **ブランチ作成（実装より前に必ず実行）**: `git checkout -b feat/topic-name`
2.  **実装**: 必要な Nix ファイルを編集．
3.  **検証**:
    - `nix flake check`（pre-commit の nixfmt / statix / convco を通すこと．statix W:20 を避けるため，同じトップレベルキーはまとめて attrset で定義し，分割して記述しない）
    - `sudo nixos-rebuild dry-activate --flake .#BrokenPC`
4.  **適用**: `sudo nixos-rebuild switch --flake .#BrokenPC` （適用前にユーザー承認を得ること）
5.  **コミットとプッシュ**:
    ```bash
    git add -A
    git commit -m "feat: topic description"
    git push origin feat/topic-name
    ```
6.  **PRの作成とマージ (GitHub CLI `gh` の使用)**:
    - ユーザー承認のうえ，以下のコマンドで PR を作成・マージします．
    - **PR作成**:
      PR 説明文は必ず一時ファイルに書いて `--body-file` で渡すこと（`--body` に特殊記号（`` ` `` など）を含めるとシェルがコマンド置換して本文が壊れるため）．
      ```bash
      cat > /tmp/pr-body.md <<'EOF'
      feat: topic description
      ...
      EOF
      gh pr create --title "feat: topic description" --body-file /tmp/pr-body.md
      ```
    - **CI 結果の確認（推奨）**: マージ前に `gh pr checks` で `nix flake check` の結果を確認する．CI が重いため，即マージを優先するなら CI 完了を待たず進めてもよいが，リスクを避けたい場合は `PASS` を待つのを推奨．どちらの運用にするかはその都度ユーザーと合意する．
    - **PRマージ＆リモートブランチ削除**:
      ```bash
      gh pr merge --merge --delete-branch
      ```
    - **ローカル main の同期**:
      ```bash
      git checkout main
      git pull origin main
      ```


---

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

---

## モジュール読み込みフロー

```text
flake.nix（flake-parts エントリポイント）
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
hosts/<name>/default.nix（各ホストのエントリ）
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

## 編集ガイド（パッケージ・モジュールを追加するとき）

### パッケージを追加するとき

- **全ホスト共通のシステムツール**: `nixos/environment/<カテゴリ>.nix` の `environment.systemPackages` に追記する．カテゴリ新設は `nixos/environment/default.nix` に `my.packages.<name>.enable` を定義してから使う
- **特定ホストだけ**: `hosts/<name>/default.nix` で `environment.systemPackages` を直接追記する
- **サービスに付随するツール**: そのサービスのモジュール内に追記する（例: `nixos/services/minecraft/` 配下）
- **desktop 専用（GUI アプリ等）**: `home/desktop/<カテゴリ>.nix` の `home.packages` に追記する（例: theme.nix, gaming.nix）．`home/desktop` は `nixos/profiles/desktop` 経由でのみ読み込まれるため，desktop ホストにしか影響しない
- **ユーザー共通ツール**: `home/programs/` 配下（home-manager の `programs.*.enable` パターン．例: cli-tools.nix）

### モジュール・サービスを追加するとき

1. 対応ディレクトリにモジュールを作成し，親の `default.nix` の imports に追加する
   - 新サービス: `nixos/services/<name>/default.nix` + `nixos/services/default.nix`
   - 新ハードウェア: `nixos/hardware/<name>.nix` + `nixos/hardware/default.nix`
   - desktop 新機能: `home/desktop/<name>.nix` + `home/desktop/default.nix`
2. オプションは `my.*` 体系で定義する（例: `options.my.services.<name>.enable` を宣言し，`mkEnableOption` でフラグ化）
3. 使いたいホストの設定で `my.<カテゴリ>.<name>.enable = true;` を指定する

### 設計原則（機能追加時の配置と記述の判断基準）

- **profiles/*.nix に設定を直書きしない**: プロファイルファイル（例: `nixos/profiles/desktop/default.nix`）には options 定義・imports・具体的なシステム設定を書かず，`my.*` オプションを持つモジュールを `nixos/services/`（または `home/desktop/`）に作成し，プロファイル側は `enable` フラグ（1行）のみ記述する．
- **home/ と nixos/ の関心事を分離する**:
  - `home/`（home-manager，特に `home/desktop`）: ユーザーが使う GUI アプリ・パッケージ（`home.packages`）とユーザー設定
  - `nixos/`（特に `nixos/services/`）: システムサービス，`/etc` 設定（`networking.hosts` など），カーネル・システム連携
  - 判断基準: 「ユーザーが直接使うデスクトップアプリ」なら home 側，「`/etc` へ書くなどシステム全体に効く設定を含む」なら nixos 側に置く．両方に及ぶ場合は home（アプリ）と nixos（hosts 等のシステム要件）に役割を分ける（例: ランチャー本体は home，hosts ルールは nixos/services）．
- **既存モジュールへの統合を優先する**: 新機能は関連する既存モジュールカテゴリに統合する（例: ゲーム関連は `nixos/services/desktop/gaming.nix` や `home/desktop/gaming.nix`）．単独ファイル化は機能が大きく，既存と分離しないと維持しづらい場合のみ．フラグはデフォルト enable にするなどしてプロファイル側の記述を簡潔に保つ．

### 新ホストを追加するとき

詳細手順書は `hosts/README.md`（SOPS / Nebula 含むエンドツーエンド）を参照し，「ユーザー承認」を必ず得ること．テンプレートは `hosts/_template/` をコピーして使う．

1. `git checkout -b feat/add-<hostname>`
2. `cp -r hosts/_template hosts/<hostname>` し，`HOSTNAME` プレースホルダ・`hardware.nix`（fileSystems/swap）・`services/nebula.nix`（IP/groups）を実機に合わせて編集
3. `flake/hosts.nix` に `mkLib.mkSystem { name; system; username; profile; extraModules?; }` を追加する（`profile` は必ず指定）
4. SOPS: `.sops.yaml` に age 鍵を登録し `secrets/hosts/<hostname>.yaml` を作成，`sops updatekeys`（詳細は `hosts/README.md` / `secrets/README.md`）
5. Nebula: 既存 CA で `nebula-cert sign` → `scripts/nebula-lib.sh` の `FLEET` 配列に追記して import（master 鍵が必要）
6. 検証: `nix flake check` → `nixos-rebuild dry-activate --flake .#<name>`（dry-activate はユーザーが実行）
7. 適用・PR は通常フロー（ユーザー承認必須）

### 新プロファイルを追加するとき

1. `nixos/profiles/<name>/default.nix` を作成し，役割共通の設定を集約する
2. 使うホストの `flake/hosts.nix` で `profile = "<name>";` を指定する

## モジュール評価順序の注意

- mkSystem の modules リストは `profile → hosts/<name>/default.nix → extraModules` の順で評価される（後勝ち）
- つまり**ホスト固有設定（hosts/<name>）がプロファイルの設定を上書きできる**
- `environment.systemPackages` のようなリスト型オプションはマージ順に連結されるため，モジュール構成を変えると順序が変わり drv が変わる（パッケージ集合は不変なので実害は通常ない）
- 優先度を明示的に制御したい場合は `mkForce` / `mkDefault` / `mkOrder` を使用する

---

## ナレッジ＆開発ベストプラクティス（Cachix & Flakes 最適化）

今後の追加開発や設定最適化において，開発エージェントが従うべき重要な知見およびベストプラクティスです．

### 1. Nix Flake 外部入力のキャッシュ最適化（follows 制約の注意）
- **Cachix キャッシュとのハッシュ一致**:
  `ghostty` のような重たいコンパイルを必要とする外部 Flake パッケージを導入する際，`inputs.nixpkgs.follows = "nixpkgs";` のようにローカルの nixpkgs に追従させる制約（`follows`）を無自覚に付与すると，Cachix 側でビルドされたパッケージのハッシュ値と不一致が発生します．
- **ビルド回避の判断**:
  Cachix のビルド済みバイナリを確実に利用（ダウンロード）するためには，該当パッケージが求めるオリジナルの nixpkgs 依存関係のままで動かすことが望ましいです．ただし，follows を外すと不要な nixpkgs インスタンスの複製（ディスク消費）が発生する可能性があるため，`dry-build` を使って「本当に重たい Zig/C コンパイルが走っているのか，それとも一瞬で終わる軽量な Nix ラッパー（`-nix`など）のみのビルドなのか」を必ず検証し，follows 制約の有無を論理的に判断してください．

### 2. Cachix バイナリキャッシュの優先度（Priority）設計
- **クエリ評価順序の最適化**:
  `nixos/base/nix.nix` の `extra-substituters` に登録するキャッシュ URL には，`?priority=` パラメータを明示的に付与して評価の優先順位を制御します．
  - **専門枠 (priority=30)**: `ghostty`, `niri` など（公式の `40` より先にヒットさせたいもの）
  - **コミュニティ枠 (priority=41)**: `nix-community` （公式の直後）
  - **特定専門枠 (priority=45)**: `cuda-maintainers`, `nix-gaming`
  - **魔改造枠 (priority=50)**: `chaotic-nyx` （他と競合するリスクがあるため最後尾）
- **記述の一貫性**:
  `extra-substituters` の並び順と，`extra-trusted-public-keys` の公開鍵の並び順は，視認性と管理のしやすさのために**完全に一致**させて記述してください．
- **一元管理**:
  Cachix の `extra-substituters` / `extra-trusted-public-keys` は必ず `nixos/base/nix.nix`（全ホスト共通）で管理する．外部フレークの提供する `nixConfig` をプロファイル等で直接参照して `nix.settings = <flake>.nixConfig;` と書くのは避け，同値の内容（substituter URL と trusted-public-keys）を base/nix.nix に手動で追加する．優先度・並び順も base/nix.nix で統一する．

---



## 便利なコマンド集

- **デプロイ**: `sudo nixos-rebuild switch --flake .#BrokenPC`
- **torii-chan デプロイ (手動/SBC用)**: `nixos-rebuild switch --flake .#torii-chan-hdd --target-host t3u@10.0.0.1 --sudo --ask-sudo-password --option sandbox false --option filter-syscalls false`
- **秘密情報編集**: `sops secrets/secrets.yaml`
- **IPC 操作 (Noctalia)**: `noctalia ipc call <target> <function>`
- **ビルド完了通知**: `curl -X POST ...` (ビルド成功時に webhook をトリガーする場合)
- **PR作成 (GitHub CLI)**: `gh pr create --title "タイトル" --body-file /tmp/pr-body.md`（本文は `--body-file` で渡し，特殊文字はファイルで安全に扱う）
- **PRマージ (GitHub CLI)**: `gh pr merge --merge --delete-branch`

