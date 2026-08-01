# NixOS 設定構築 - 運用・開発ガイド

このドキュメントは、本リポジトリの設計思想、開発ワークフロー、および作業履歴を管理するためのものです。

---

## プロジェクト概要

本リポジトリは、宣言的で高度にカスタマイズされたデスクトップ環境及びサーバー群の構築を目指しています。

---

## 開発ワークフロー

### 1. 作業の基本ルール
- **ブランチ戦略**: 直接 `main` にコミットせず、**作業を開始する前（いかなるファイル編集前）に必ず** ブランチを作成・切り替えてください。`main` 上でファイルを編集してからブランチを切る行為は禁止します。
- **ブランチ命名規約**: Conventional Commits の型に揃え、`feat/<名前>`・`fix/<名前>`・`refactor/<名前>`・`docs/<名前>`・`chore/<名前>` のいずれかを使用します（必要ならばこの5種を超えてもよい）。`.github/workflows/nix-check.yml` の push 対象と `devenv.nix` の `git-hooks`（convco による Conventional Commits 検証）と整合するよう、新たな型を追加する場合は**三方同時に更新**してください。
- **対応言語**: ユーザーへの報告、相談はすべて **日本語** で行います。
- **バイリンガル対応 (Bilingual Sync)**: プロジェクトルートの `README.md` および `README.ja.md` は、必ず英語と日本語の両方を同時に同期して更新してください。サブディレクトリの `README.md` は英語のみで管理し、日英の重複管理は行いません。
- **ドキュメント優先**: 変更の際は `TODO.md` や `README.md` との整合性を確認してください。
- **コミット方針**: 適切なコミットメッセージ（Conventional Commits 準拠など）と共にコミットし、変更内容の詳細はコミットメッセージおよび PR (Pull Request) の説明に詳しく記述してください。作業ログファイル（`.agents/` 等）の個別作成は廃止されました。
- **ユーザー承認の義務化**: `main` へのマージ、リモートの `main` へのプッシュ、および `nixos-rebuild switch` の適用を行う際は、必ず実行前にユーザーへ明示的に確認し、承認を得てから進めてください。

### 2. 変更・適用手順
1.  **ブランチ作成（実装より前に必ず実行）**: `git checkout -b feat/topic-name`
2.  **実装**: 必要な Nix ファイルを編集。
3.  **検証**:
    - `nix flake check`
    - `sudo nixos-rebuild dry-activate --flake .#BrokenPC`
4.  **適用**: `sudo nixos-rebuild switch --flake .#BrokenPC` （適用前にユーザー承認を得ること）
5.  **コミットとプッシュ**:
    ```bash
    git add .
    git commit -m "feat: topic description"
    git push origin feat/topic-name
    ```
6.  **PRの作成とマージ (GitHub CLI `gh` の使用)**:
    - ユーザー承認のうえ、以下のコマンドで PR を作成・マージします。
    - **PR作成**:
      PR 説明文は必ず一時ファイルに書いて `--body-file` で渡すこと（`--body` に特殊記号（`` ` `` など）を含めるとシェルがコマンド置換して本文が壊れるため）。
      ```bash
      cat > /tmp/pr-body.md <<'EOF'
      feat: topic description
      ...
      EOF
      gh pr create --title "feat: topic description" --body-file /tmp/pr-body.md
      ```
    - **CI 結果の確認（推奨）**: マージ前に `gh pr checks` で `nix flake check` の結果を確認する。CI が重いため、即マージを優先するなら CI 完了を待たず進めてもよいが、リスクを避けたい場合は `PASS` を待つのを推奨。どちらの運用にするかはその都度ユーザーと合意する。
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
- `nixos/networking/`: ネットワーク・VPN（WireGuard, Hosts）
- `nixos/environment/`: システムパッケージ
- `nixos/hardware/`: ハードウェア固有設定
- `nixos/profiles/`: 役割別プロファイル
- `nixos/services/`: システムサービス
- `home/shell/`: ユーザーシェル環境（Zsh, Starship, Atuin）
- `home/programs/`: 共通ワークステーションツール（CLIツール, Git, SSH）
- `home/desktop/`: GUI アプリ、WM (Niri/Noctalia)
- `hosts/`: マシン固有の定義
- `secrets/`: SOPS による機密情報管理
- `docs/`: 設計計画書やシステムアーキテクチャのドキュメント管理用


---

## ナレッジ＆開発ベストプラクティス（Cachix & Flakes 最適化）

今後の追加開発や設定最適化において、開発エージェントが従うべき重要な知見およびベストプラクティスです。

### 1. Nix Flake 外部入力のキャッシュ最適化（follows 制約の注意）
- **Cachix キャッシュとのハッシュ一致**:
  `ghostty` のような重たいコンパイルを必要とする外部 Flake パッケージを導入する際、`inputs.nixpkgs.follows = "nixpkgs";` のようにローカルの nixpkgs に追従させる制約（`follows`）を無自覚に付与すると、Cachix 側でビルドされたパッケージのハッシュ値と不一致が発生します。
- **ビルド回避の判断**:
  Cachix のビルド済みバイナリを確実に利用（ダウンロード）するためには、該当パッケージが求めるオリジナルの nixpkgs 依存関係のままで動かすことが望ましいです。ただし、follows を外すと不要な nixpkgs インスタンスの複製（ディスク消費）が発生する可能性があるため、`dry-build` を使って「本当に重たい Zig/C コンパイルが走っているのか、それとも一瞬で終わる軽量な Nix ラッパー（`-nix`など）のみのビルドなのか」を必ず検証し、follows 制約の有無を論理的に判断してください。

### 2. Cachix バイナリキャッシュの優先度（Priority）設計
- **クエリ評価順序の最適化**:
  `nixos/base/nix.nix` の `extra-substituters` に登録するキャッシュ URL には、`?priority=` パラメータを明示的に付与して評価の優先順位を制御します。
  - **専門枠 (priority=30)**: `ghostty`, `niri` など（公式の `40` より先にヒットさせたいもの）
  - **コミュニティ枠 (priority=41)**: `nix-community` （公式の直後）
  - **特定専門枠 (priority=45)**: `cuda-maintainers`, `nix-gaming`
  - **魔改造枠 (priority=50)**: `chaotic-nyx` （他と競合するリスクがあるため最後尾）
- **記述の一貫性**:
  `extra-substituters` の並び順と、`extra-trusted-public-keys` の公開鍵の並び順は、視認性と管理のしやすさのために**完全に一致**させて記述してください。

### 3. Ghostty 特有の設定上の罠
- **ウィンドウ枠非表示オプションの名称**:
  ウィンドウデコレーション（タイトルバーなど）をオフにするオプション名は、複数形の `window-decorations` ではなく、**単数形の `window-decoration`** です（`window-decoration = false`）。
- **テーマカラー動的同期エラーの回避**:
  Noctalia などの外部ツールが動的に生成するテーマカラーファイルを `config-file` で読み込む場合、ファイルがまだ存在しないタイミングでの起動エラー（`FileNotFound`）を防ぐため、パスの先頭にプレフィックス **`?`** を付与してください（例: `config-file = "?/path/to/ghostty-colors"`）。これにより、ファイル未生成時もサイレントに無視してフォールバック起動させることができます。

### 4. GNOME環境外における XDG Desktop Portal の挙動とファイル選択の罠
- **GNOMEポータルの不作動問題**:
  Niri などの非GNOMEコンпозиター環境で `xdg-desktop-portal-gnome` を最優先ポータルとして使用すると、ファイル選択ダイアログ (`org.freedesktop.impl.portal.FileChooser`) 等が動作しません。これは、GNOME ポータルが GNOME Shell の D-Bus インターフェースや GNOME セッションに強く依存しているためです。
- **回避策（明示的なGTKポータル指定）**:
  ポータル設定 (`xdg.portal.config`) にて、`FileChooser` および `AppChooser` に対応するポータルとして `gtk` (`xdg-desktop-portal-gtk`) を明示的に優先指定することで、非GNOME環境でも正常に GTK ベースのファイル選択ダイアログが起動するようになります。

---



## 便利なコマンド集

- **デプロイ**: `sudo nixos-rebuild switch --flake .#BrokenPC`
- **torii-chan デプロイ (手動/SBC用)**: `nixos-rebuild switch --flake .#torii-chan --target-host t3u@10.0.0.1 --use-remote-sudo --ask-sudo-password --option sandbox false --option filter-syscalls false`
- **秘密情報編集**: `sops secrets/secrets.yaml`
- **IPC 操作 (Noctalia)**: `noctalia ipc call <target> <function>`
- **ビルド完了通知**: `curl -X POST ...` (ビルド成功時に webhook をトリガーする場合)
- **PR作成 (GitHub CLI)**: `gh pr create --title "タイトル" --body-file /tmp/pr-body.md`（本文は `--body-file` で渡し、特殊文字はファイルで安全に扱う）
- **PRマージ (GitHub CLI)**: `gh pr merge --merge --delete-branch`

