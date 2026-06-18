# NixOS 設定構築 - 運用・開発ガイド

このドキュメントは、本リポジトリの設計思想、開発ワークフロー、および作業履歴を管理するためのものです。

---

## 🚀 プロジェクト概要

本リポジトリは、宣言的で高度にカスタマイズされたデスクトップ環境及びサーバー群の構築を目指しています。

---

## 🛠️ 開発ワークフロー

### 1. 作業の基本ルール
- **ブランチ戦略**: 直接 `main` にコミットせず、`feature/<name>` または `refactor/<name>` ブランチを作成してください。
- **対応言語**: ユーザーへの報告、相談はすべて **日本語** で行います。
- **バイリンガル対応 (Bilingual Sync)**: プロジェクト内のドキュメント（ルートおよび各ディレクトリの `README.md` と `README.ja.md` 等）は、必ず**英語と日本語の両方を同時に同期して更新**してください。
- **ドキュメント優先**: 変更の際は `TODO.md` や `README.md` との整合性を常に確認してください。
- **コミット方針**: ブランチ内でのコミットは、検証に成功して問題がないと判断されれば、エージェント自身の裁量で適切なコミットメッセージ（Conventional Commits 準拠など）と共にコミットして構いません。
- **ユーザー承認の義務化**: `main` へのマージ、リモートの `main` へのプッシュ、および `nixos-rebuild switch` の適用を行う際は、必ず実行前にユーザーへ明示的に確認し、承認を得てから進めてください。

### 2. 変更・適用手順
1.  **ブランチ作成**: `git checkout -b feature/topic-name`
2.  **実装**: 必要な Nix ファイルを編集。
3.  **検証**:
    - `nix flake check`
    - `sudo nixos-rebuild dry-activate --flake .#BrokenPC`
4.  **適用**: `sudo nixos-rebuild switch --flake .#BrokenPC` （適用前にユーザー承認を得ること）
5.  **記録**: `.agents/work-logs/` に作業ログを作成し、`AGENTS.md` の履歴を更新。
6.  **コミットとプッシュ**:
    ```bash
    git add .
    git commit -m "feat: topic description"
    git push origin feature/topic-name
    ```
7.  **PRの作成とマージ (GitHub CLI `gh` の使用)**:
    - ユーザー承認のうえ、以下のコマンドで PR を作成・マージします。
    - **PR作成**:
      ```bash
      gh pr create --title "feat: topic description" --body "Detailed description of changes"
      ```
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

## 📖 構成ディレクトリ構造

- `modules/core/`: システム基盤（Network, Sops, Nix）
- `modules/home/`: ユーザー環境（Home-manager）
    - `desktop/`: GUI アプリ、WM (Niri/Noctalia)
    - `shell/`: Zsh, Starship, CLI ツール
- `hosts/`: マシン固有の定義
- `secrets/`: SOPS による機密情報管理

---

## 🧠 ナレッジ＆開発ベストプラクティス（Cachix & Flakes 最適化）

今後の追加開発や設定最適化において、開発エージェントが従うべき重要な知見およびベストプラクティスです。

### 1. Nix Flake 外部入力のキャッシュ最適化（follows 制約の注意）
- **Cachix キャッシュとのハッシュ一致**:
  `ghostty` のような重たいコンパイルを必要とする外部 Flake パッケージを導入する際、`inputs.nixpkgs.follows = "nixpkgs";` のようにローカルの nixpkgs に追従させる制約（`follows`）を無自覚に付与すると、Cachix 側でビルドされたパッケージのハッシュ値と不一致が発生します。
- **ビルド回避の判断**:
  Cachix のビルド済みバイナリを確実に利用（ダウンロード）するためには、該当パッケージが求めるオリジナルの nixpkgs 依存関係のままで動かすことが望ましいです。ただし、follows を外すと不要な nixpkgs インスタンスの複製（ディスク消費）が発生する可能性があるため、`dry-build` を使って「本当に重たい Zig/C コンパイルが走っているのか、それとも一瞬で終わる軽量な Nix ラッパー（`-nix`など）のみのビルドなのか」を必ず検証し、follows 制約の有無を論理的に判断してください。

### 2. Cachix バイナリキャッシュの優先度（Priority）設計
- **クエリ評価順序の最適化**:
  `modules/core/nix.nix` の `extra-substituters` に登録するキャッシュ URL には、`?priority=` パラメータを明示的に付与して評価の優先順位を制御します。
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

## 📜 過去の履歴とログ
- [2026-06-18: Noctalia v5 移行に伴うオプション・バイナリ名の修正](./.agents/work-logs/2026-06-18-fix-noctalia-v5.md)
- [2026-06-18: desktopプロファイルへ Unity Hub の追加](./.agents/work-logs/2026-06-18-add-unityhub.md)
- [2026-06-06: ファイルマネージャからテキストファイルを開く際のデフォルトエディタを Neovim に設定](./.agents/work-logs/2026-06-06-fix-default-text-editor-nvim.md)
- [2026-06-06: VLC 動画再生サイズ不具合の修正、Vesktop 設定の整理、および Thunar 最近使用したファイルの非表示化](./.agents/work-logs/2026-06-06-desktop-rules-vlc-vesktop.md)
- [2026-06-06: XDG Desktop Portal の設定調整によるファイル選択ダイアログ不具合の修正](./.agents/work-logs/2026-06-06-fix-portal-file-chooser.md)
- [2026-06-05: Noctalia Shell の follows 先最適化による不整合リスク回避](./.agents/work-logs/2026-06-05-optimize-noctalia-follows.md)
- [2026-06-05: XDG Mime Apps の調整と Thunar / アーカイブ展開機能の不具合修正](./.agents/work-logs/2026-06-05-fix-xdg-mime-apps-thunar.md)
- [2026-06-01: デスクトップ専用モジュールへの GPG 署名・Ghostty terminfo の移行とサーバー側復号エラーの解消](./.agents/work-logs/2026-06-01-sops-desktop-only-gpg-and-ghostty-terminfo-fix.md)
- [2026-06-01: SOPS 最小権限パーミッション移行の完了と検証](./.agents/work-logs/2026-06-01-sops-permissions-refactoring-completed.md)
- 詳細は [作業ログのディレクトリ](./.agents/work-logs/) を参照してください。


---

## 💡 便利なコマンド集

- **デプロイ**: `sudo nixos-rebuild switch --flake .#BrokenPC`
- **torii-chan デプロイ (手動/SBC用)**: `nixos-rebuild switch --flake .#torii-chan --target-host t3u@10.0.0.1 --use-remote-sudo --ask-sudo-password --option sandbox false --option filter-syscalls false`
- **秘密情報編集**: `sops secrets/secrets.yaml`
- **IPC 操作 (Noctalia)**: `noctalia-shell ipc call <target> <function>`
- **ビルド完了通知**: `curl -X POST ...` (詳細は `AGENTS.history.md` 参照)
- **PR作成 (GitHub CLI)**: `gh pr create --title "タイトル" --body "説明文"`
- **PRマージ (GitHub CLI)**: `gh pr merge --merge --delete-branch`

---

> [!TIP]
> 作業ログを作成する際は、`2026-03-28-topic.md` のように日付を含めたファイル名にしてください。
