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
- [x] **NVIDIA ドライバ設定の抽象化 (feature/systematic-refinement)**:
  - `shosoin-tan`, `kagutsuchi-sama`, `BrokenPC` で重複していた設定を `modules/hardware/nvidia.nix` に集約。
  - PRIME（ハイブリッドGPU）構成のオプション化とアーキテクチャ対応 (x86_64/AArch64)。
- [x] **システムパッケージ層の整理と堅牢化**:
  - `modules/packages/` の再編により、ベースシステムとユーザー環境の境界を明確化。
  - `minecraft` や `gaming` サービスのオプトイン方式への変更によるビルドの安定化。
- [x] **デスクトップ環境の高度な同期 (Noctalia / Matugen / Neovim)**:
  - Noctalia バーへの CPU/RAM 監視ウィジェットの追加。
  - Matugen テンプレートによる Neovim 配色テーマの動的同期実装。
- [x] **低リソース機向けデプロイプロセスの最適化**:
  - `nixos-rebuild --build-host` を活用したリモートビルド・デプロイ手順の確立。
- [x] **ファイルマネージャーの実用性向上 (Phase 7)**:
  - Nautilus から Thunar への完全移行と Recent Files の無効化。
  - `gvfs`, `tumbler` によるゴミ箱・マウント・サムネイル機能の統合。
- [x] **デプロイ基盤の刷新と CI/CD (Phase 7)**:
  - セキュリティと運用の容易さを考慮し、自作 Update Hub を廃止し `comin` による Git-pull 型デプロイへ移行。
  - GitHub Actions を用いた `nix flake check` の自動化準備。
---

### **進行中・今後のタスク**

- [ ] **SOPS 機密情報の構造化と権限分離**:
  - 現在 `secrets/secrets.yaml` に集中している機密情報を、ホスト別・サービス別に分割し、各ホストの復号権限を最小化する。
- [ ] **艦隊ダッシュボードの作成**:
  - `comin` には管理 UI がないため、全ホストのバージョンやデプロイ状況を一覧できる Noctalia ウィジェットや軽量 Web アプリを構築する。
- [ ] **Steam**: `Millennium` 導入による動的テーマ適用。
- [ ] **torii-chan負荷対策**: 非力なtorii-chanでのビルドを別のホストで肩代わりする。また、shellの設定も調整する。
- [ ] **torii-chan設定の汎用化**: torii-chanの設定を汎用化し、他のホスト(VPS等)でも利用できるようにする。
- [ ] **フェイルオーバーVPSの導入**: torii-chanとの接続が切れた場合に動的にVPSへと切り替える仕組みを導入する。Vultrなどの従量課金制の格安VPSのAPIを利用するのが良さそう。CNAMEで動的に切り替えられるようにする。
- [ ] **fcitx5の調整**: 勝手にオフになる現象の原因を調査し、修正する。
- [ ] **キャッシュサーバーの導入**: それぞれのホストでのビルドキャッシュを共有できるようにする。また、ライセンスの問題でビルドキャッシュを公開できないパッケージのプライベートキャッシュを導入する。
- [ ] **オニオンルーティングによるsshバックドアの導入**: torii-chanがダウンした際に、オニオンルーティング経由でssh接続できるようにする。
- [ ] **ローカルLLMの導入**: kagutsuchi-samaやshosoin-tanのGPUでローカルLLMサーバーをホストし、利用できるようにする。
- [ ] **Tailscale / Headscale への移行**: モダンなVPNサービスであるTailscaleまたはHeadscaleを導入し、よりセキュアで便利なリモートアクセス環境を構築する。
- [ ] **BrokenPCバックアップサーバーの構築**: BrokenPCのバックアップサーバーを構築する。データを自動でバックアップする。
- [ ] **監視サービスの強化**: 監視サービスを強化し、また重要なセキュリティ情報やサービスの失敗を通知するシステムを構築する。