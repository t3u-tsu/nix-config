# 2026-03-28: デスクトップ最適化 & 監視基盤配備 (Phase 8 - 8.5)

## 🎯 概要
本セッションでは、Nari + Noctalia 環境のさらなる視覚的洗練と、全ホスト(`desktop`, `tower-server`)を束ねる統合監視基盤の構築を実施しました。また、Github Actions による継続的インテグレーション(CI)を追加しました。

## 🛠️ 実施内容

### 1. ターミナル環境の刷新 (WezTerm x Noctalia)
- Alacritty を廃止し、NixOS モジュールにて WezTerm を導入 (`modules/home/desktop/dev-tools/wezterm.nix`)。
- Noctalia (Matugen) が壁紙から生成した Lua テンプレート (`wezterm-colors.lua`) を `dofile()` で読み込む手法を確立し、動的テーマに完全同期。
- WezTerm の内部 `window_padding` をゼロにし、UIの隙間問題を解消。

### 2. Steam Millennium 公式対応
- 手動のシェルスクリプトダウンロードを廃止し、公式 Nix Flake (`github:SteamClientHomebrew/Millennium`) によるオーバーレイ環境を構築。
- システムレベルの `programs.steam.package` を `millennium-steam` に置換。

### 3. Wayland UI 競合解決とダークモード強制
- **隙間バグの恒久対応**: ログイン起動時、Niri コンポジタのレイアウト生成に Noctalia バーが割り込む競合（Race Condition）を特定。`noctalia-shell.service` に `ExecStartPre = "sleep 2"` を付与し解消。
- **ダークモード強制**: 非常に明るい壁紙使用時にライトテーマが生成される問題を回避するため、Matugen テンプレートの参照変数を `{{colors.xxx.default.hex}}` から `{{colors.xxx.dark.hex}}` に全置換。これにより動的抽出を維持しつつダークパレットを完全固定。また、エディタ(IDE)が眩しい問題に対し GTK の `syncGsettings = true` を設定。

### 4. CI/CD および 艦隊監視ダッシュボード構築
- **CI/CD**: `.github/workflows/nix-check.yml` を新設し、Push 時に `nix flake check --show-trace` を自動実行。
- **Prometheus + Node Exporter**: 全ての Desktop/Server 機ノードに対し `node_exporter` (port: 9100) を配備するモジュールを新造 (`modules/services/monitoring/default.nix`)。
- **Grafana 司令塔**: `torii-chan` サーバーを監視のハブとし、Prometheus サーバーおよび Grafana Web UI (port: 3000) をデプロイ。

## 🔧 次のアクション・課題
- Grafana 初期設定 (ダッシュボード画面のインポート等)
- 各種秘密情報 (sops-nix) の細分化
