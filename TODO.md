# リポジトリ改善 TODO リスト

このリストは、NixOS 設定リポジトリのさらなる保守性・拡張性向上のための提案を優先度別にまとめたものです。

---

### **完了済みタスク**
- [x] **Niri & Noctalia Shell 構成の高度化 (feature/noctalia-ultimate-optimization)**:
  - `noctalia-shell` の内蔵機能を活用し、重複している外部ツール（`brightnessctl`, `playerctl` 等）を排除。
  - バー、ウィジェット、通知、OSD の詳細構成を刷新。
  - Niri のキーバインドを `noctalia-shell ipc` 経由に統一。
  - `spicetify-nix` による Spotify の Dracula テーマ適用。
  - 日本語入力 (Fcitx5/Mozc) の Home-manager による安定管理と環境同期。
  - ハードウェア開発ツール (KiCad, Picocom) の導入と dialout グループ権限設定。
  - AI開発プラットフォーム (antigravity) の導入。
- [x] **Sops 共通設定の整理**: `modules/core/sops.nix` への集約。
- [x] **リポジトリ所有権の強制**: `update-hub` での `chown` 実施。
- [x] **コマンドの即時実行環境 (nix-index / comma) の構築**: 全ホストへの導入完了。
- [x] **Shell UI の刷新 (Starship)**: 全ホストへの導入とコンパクト化。
- [x] **Home-manager 設定の構造化**: `modules/home/` 配下への機能別分割。
- [x] **デスクトップ構成の高度な構造化**: カテゴリー別オプション化と `dev-tools` のディレクトリ化。
- [x] **Zen Browser の宣言的カスタマイズ**: 拡張機能、コンテナ、検索エンジンの自動構成。
- [x] **Niri デスクトップ環境への完全移行**: 
    - Niri 本体、noctalia-shell、awww (wallpaper)、swaync 等の統合完了。
    - greetd (tuigreet) による TUI ログイン環境の構築。
    - Omarchy + Vim スタイルのハイブリッドキーバインド実装。
- [x] **システム全体のテーマ統一 (Dracula Theme)**: Alacritty, GTK, Qt を含めた配色統一。
- [x] **リポジトリ全体のドキュメント整備**: 各モジュールへの README.md / README.ja.md 完備。
- [x] **デスクトップ環境の最適化 (feature/optimize-ui-and-office)**:
  - Noctalia バーの影を無効化し、UI の隙間を解消。
  - スクショキー (PrintScreen) の動作修正（Niri ネイティブ機能。
  - LibreOffice の導入と Excel/Word 等のファイル関連付け。
  - Zen Browser の設定クリーンアップ。
- [x] **AI ツールの導入**: `gemini-cli` (unstable) の追加。

---

### **進行中・今後のタスク**

- [ ] **デスクトップ環境の継続的改善**:
  - **Noctalia 動的テーマ同期 (Matugen integration) の完遂**: Matugen テンプレートによる Zen Browser / Discord の配色同期の安定化（HM直轄 Matugen の導入検討）。
  - **バー・OSD の微調整**: ウィジェットのレイアウトや通知アニメーションの洗練。
  - **Steam**: `Millennium` 導入による動的テーマ適用。
  - **Neovim**: `noctalia.nvim` プラグインの導入検討と、配色テーマの連動。
- [ ] **SOPS 機密情報の構造化と権限分離**:
  - 現在 `secrets/secrets.yaml` に集中している機密情報を、ホスト別・サービス別に分割し、各ホストの復号権限を最小化する。
- [ ] **低リソース機向けの分散ビルド (Remote Build) 導入**:
  - `torii-chan` (RAM 1GB) 等でのビルド負荷を軽減するため、他の強力なマシンをビルドホストとして利用する設定を構築する。
- [ ] **NVIDIA ドライバ設定の抽象化**:
  - `shosoin-tan`, `kagutsuchi-sama`, `BrokenPC` で重複している設定を `modules/hardware/nvidia.nix` 等に抽出し、構成をオプション化する。
- [ ] **Update Hub のセキュリティ強化**:
  - サービスの実行ユーザーを非 root に変更し、権限を制限する。
- [ ] **CI/CD の構築**:
  - GitHub Actions 等で `nix flake check` を自動実行し、品質を担保する。
- [ ] **システムパッケージ層の整理**:
  - `modules/packages/` の構成をさらに見直し、ベースシステムとユーザー環境の境界を洗練させる。
