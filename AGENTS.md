# NixOS設定構築 - 開発運用ガイド

## 📋 最新セッション

- **2026-03-27**: [デスクトップ最適化 Phase 1](./.agents/work-logs/2026-03-27-desktop-optimization.md)
  - Noctalia UI 改善、キーバインド統一、Vesktop 調整

詳細は [作業ログ](./agents/work-logs/) を参照。

---

## 運用ルール
- ユーザーとの対話、説明、進捗報告などのメッセージは**すべて日本語**で行うこと。
- 開発ワークフローについては`開発ワークフロー`セクションの手順を**絶対遵守**すること。

### 構成マインドセット
- **`modules/`**: 再利用可能な「仕組み」の置き場。
  - `core/`: 基盤設定（Nix, Network, etc.）
  - `packages/`: 機能別パッケージパック
  - `shell/`: Zsh & Home-manager による環境統合
  - `services/`: 各種サーバーサービス
  - `profiles/`: 役割ごとのプリセット
- **`hosts/`**: マシンごとの「実体」定義。`modules/` から必要なものを組み合わせて構成する。

### 開発ワークフロー
  0. 作業の開始前に、関連する全ての`README.md`を読み、内容を把握してから作業を開始すること。
  1. **作業ブランチの作成**: 原則として `main` で直接作業せず、`feature/xxx` や `refactor/xxx` ブランチを作成して作業する。
  2. **変更と追跡**: ファイルを作成・変更したら `git add .` する（Flake は Git 管理下のファイルのみ認識するため）。
  3. **安全性検証**:
     - `nix flake check` で構文と一貫性を確認。
     - `sudo nixos-rebuild dry-activate --flake .#<hostname>` でビルド可能性を最終確認。
  4. **適用とテスト**: 必要に応じて `sudo nixos-rebuild switch` を行い、ローカル環境で動作確認。
  5. **コミット・マージ**: `git commit` 後、`main` ブランチへマージする。
  6. **プッシュと通知**:
     - `git push` を実行。
     - **重要**: `curl` を使用して Hub (torii-chan) へ通知を送り、全ホストの自動更新をトリガーする。

### 主要コマンド
- torii-chan デプロイ: `nixos-rebuild switch --flake .#torii-chan --target-host t3u@10.0.0.1 --sudo`
- Hubへの通知 (一斉更新): `curl -X POST -H "Content-Type: application/json" -d "{\"commit\": \"$(git rev-parse HEAD)\", \"host\": \"$(hostname)\"}" http://10.0.0.1:8080/producer/done`
- 秘密情報の編集: `nix shell nixpkgs#sops -c sops secrets/secrets.yaml`

### 運用・デプロイ上の知見
- **Zsh & Home-manager**: 全ホストで `zsh` がデフォルト。エイリアス（ls=eza, cat=bat等）は Home-manager で一括管理。
- **ハードウェアツール**: `my.hardware.pc-tools.enable = true;` を設定したホストでのみ、物理サーバー用ツールがインストールされる。
- **パッケージ制御**: `my.packages.<category>.enable = false;` で不要なツール群を除外可能（低リソース機向け）。
- **マイクラコンソール**: `sudo tmux -S /run/minecraft/<サービス名>.sock attach`

### 作業記録 (Activity Log)
- **2026-03-10**: Niri への完全移行とデスクトップ体験の究極化。
    - **Niri** (Scrollable-Tiling) への完全移行を実施し、KDE Plasma を排除。
    - ログインマネージャを **greetd (tuigreet)** へ変更し、TUI ベースの高速な起動を実現。
    - システム全体のテーマを **Dracula** で統一（Alacritty, GTK, Qt）。
    - **awww** (Codeberg 版) によるアニメーション壁紙の導入。
    - キーバインドを **Omarchy** 風に再編し、Vim キー (HJKL) とのハイブリッド構成を実現。
    - 重複していた外部ツール（SwayNC, wlogout, swayosd, 各種アプレット）を排除し、**Noctalia Shell** の内蔵機能に完全一本化。
    - バイナリキャッシュ（niri, yazi, chaotic-nyx 等）を大幅拡充しビルドを高速化。
    - `README` に主要な参考文献（ryan4yin, omarchy-nix, natsukium, asa1984, ms0503）を明記。
- **2026-03-09**: Zen Browser の高度なカスタマイズと開発環境の構造化。
    - Zen Browser の**コンテナ設定**（Personal, School, Work）を英語名で再定義。
    - `modules/home/desktop/dev-tools/` ディレクトリを新設し、Neovim や VSCode の設定を詳細管理可能にした。
    - 拡張機能の ID 修正（YouTube NonStop, Screenshot, LINE）を行い、確実に宣言的インストールされるようにした。
    - **Alacritty** をシステムおよび KDE 側のデフォルトターミナルとして固定。
- **2026-03-09**: デスクトップ環境の大規模刷新と構成の高度化。
    - `modules/home/desktop/` をカテゴリー別（browsers, communication, dev-tools, etc.）にオプション化し、柔軟な管理を可能にした。
    - メイン環境を **Zen Browser**, **Vesktop**, **Neovim** へ刷新し、**Yazi** を導入。
    - システム全体の**ダークモード**化（Breeze-Dark）と、管理用ネットワーク経由の **SSH config 宣言的生成**を実装。
    - `nix-gaming` などのバイナリキャッシュを追加し、ビルドを高速化。
    - 開発ワークフローを「ブランチベースの検証・通知型」に洗練させた。
- **2026-03-09**: BrokenPC のネットワーク統合と SSH アクセス構成。
    - BrokenPC 用の WireGuard 鍵ペアおよび SSH 鍵ペアを SOPS (`secrets/secrets.yaml`) に統合。
    - `hosts/BrokenPC/services/wireguard.nix` を新規作成し、管理用 (`wg0`) およびアプリ用 (`wg1`) ネットワークを構築。
    - `torii-chan` のピア設定を更新し、BrokenPC との相互通信を可能にした。
    - SOPS を利用して `~t3u/.ssh/id_ed25519` を宣言的に配置。
- **2026-03-09**: BrokenPC のハードウェア構成最適化と不具合修正。
    - `hardware.enableRedistributableFirmware = true;` を有効化し、Wi-Fi (mt7921e), Bluetooth, Ethernet, AMD GPU のファームウェア読み込み失敗を解消。
    - `boot.kernelPackages = pkgs.linuxPackages_latest;` を採用し、Ryzen 6000 シリーズと故障を抱える 3050Ti に対する最新の安定性改善を導入。
    - `hardware.graphics` (OpenGL/Vulkan) を明示的に有効化。
- **2026-03-09**: BrokenPC のセットアップと Sops 構成の最適化。
    - `secrets/secrets.yaml` に `BrokenPC` 用のパスワードハッシュを追加。
    - `modules/core/sops.nix` への設定集約により、全ホストでの Sops 設定の重複を排除。
    - 1TB SSD を追加し、`/data` にマウントするよう `disko` 構成を更新。
- **2026-03-05**: リポジトリ構成の大規模再編。
    - `common/` および `services/` を `modules/` 配下へ統合。
    - パッケージ管理のオプトイン/オプトアウト化、ハードウェア特性フラグの導入。
    - 全ホストのデフォルトシェルを Zsh へ移行し、Home-manager でシェル環境を高度に統合。
