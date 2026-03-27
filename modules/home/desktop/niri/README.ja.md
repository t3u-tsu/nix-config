# Niri 設定

このディレクトリでは、Niri スクロール型タイル Wayland コンポジターとそのエコシステムを管理しています。現在は Noctalia Shell に機能を完全に一本化しています。

## 📂 コンポーネント

- **`default.nix`**: Niri のコア設定。レイアウト、ウィンドウ構成、キーバインド（Omarchy + Vim スタイル）を含みます。
- **`noctalia/`**: バー、ランチャー、通知、OSD を提供する `noctalia-shell` のモジュール化された設定。
- **`addons.nix`**: クリップボード管理（`cliphist`）やファイルマネージャ（`nautilus`）などの周辺ツール。
- **`power.nix`**: Noctalia IPC と `hypridle` による電源管理と画面ロック。

## ⌨️ 主要キーバインド

- `Mod + Return`: ターミナル (Alacritty)
- `Mod + Shift + B`: ブラウザ (Zen Browser)
- `Mod + Space`: ランチャー (Noctalia)
- `Mod + W`: ウィンドウを閉じる
- `Mod + H/J/K/L`: 移動・操作 (Vim スタイル)
- `Mod + 矢印キー`: 移動・操作 (標準)
- `Mod + V`: フローティングの切り替え
- `Mod + Escape`: セッションメニュー (Noctalia)
