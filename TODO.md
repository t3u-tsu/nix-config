# リポジトリ改善 TODO リスト

このリストは、NixOS 設定リポジトリのさらなる保守性・拡張性向上のための提案を優先度別にまとめたものです。

- [ ] **Niri & Noctalia Shell 構成の整理**:
  - `noctalia-shell` の内蔵機能を活用し、重複している外部ツール（`brightnessctl`, `playerctl` 等）を `home.packages` から削除。
  - `noctalia-shell` の詳細なバー構成（時計、CPU/メモリ使用量等）を `noctalia.nix` に追加。
  - Niri のキーバインドを `noctalia-shell ipc` 経由に完全に統一し、OSD 等の動作を安定させる。

---

### **完了済みタスク**
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
- [x] **AI ツールの導入**: `gemini-cli` (unstable) の追加。

---

### **進行中・今後のタスク**

- [ ] **SOPS 機密情報の構造化と権限分離**:
  - 現在 `secrets/secrets.yaml` に集中している機密情報を、ホスト別・サービス別に分割し、各ホストの復号権限を最小化する。
- [ ] **低リソース機向けの分散ビルド (Remote Build) 導入**:
  - `torii-chan` (RAM 1GB) 等でのビルド負荷を軽減するため、他の強力なマシンをビルドホストとして利用する設定を構築する。
- [ ] **NVIDIA ドライバ設定の抽象化**:
  - `shosoin-tan`, `kagutsuchi-sama`, `BrokenPC` で重複している設定を `modules/hardware/nvidia.nix` 等に抽出し、構成をオプション化する。
- [ ] **WireGuard 構成のモジュール化**:
  - ホスト間で重複しているピア定義を中央管理し、自動生成・同期できる仕組みを作る。
- [ ] **ZFS 設定の共通化**:
  - 共通設定を `modules/core/zfs.nix` にまとめ、各ホストの設定を簡略化する。
- [ ] **Update Hub のセキュリティ強化**:
  - サービスの実行ユーザーを非 root に変更し、権限を制限する。
- [ ] **CI/CD の構築**:
  - GitHub Actions 等で `nix flake check` を自動実行し、品質を担保する。
- [ ] **デスクトップ・ゲーミング最適化**:
  - パフォーマンスチューニング（GameMode プロファイルの微調整等）の継続。
- [ ] **システムパッケージ層の整理**:
  - `modules/packages/` の構成をさらに見直し、ベースシステムとユーザー環境の境界を洗練させる。
