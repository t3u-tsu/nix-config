# 作業ログ: XDG Mime Apps の調整と Thunar / アーカイブ展開機能の不具合修正

- 日付: 2026-06-05
- 作業ブランチ: `feature/fix-xdg-mime-apps`

## 概要

ブラウザなどでファイルやディレクトリを開く際にファイルマネージャ（Thunar）が正しく起動しない不具合、および Thunar 側でアーカイブ（ZIP等）を「展開（Extract）」しようとしても動作しない不具合を解消しました。

## 課題と原因

1. **ファイルマネージャが起動しない問題**:
   - `modules/home/desktop/xdg.nix` にて `inode/directory` （ディレクトリを開くハンドラ）が `org.gnome.Nautilus.desktop` に固定されていました。
   - Home-manager 側で `thunar` やそのプラグインを `home.packages` に追加しただけでは、D-Bus サービスとしての登録（特に `org.freedesktop.FileManager1` などの D-Bus インターフェース）が十分に行われず、XDG Desktop Portal や `xdg-open` 経由で正しく Thunar が呼び出されない状態でした。
2. **アーカイブの展開が機能しない問題**:
   - `thunar-archive-plugin` は右クリックメニューに「展開」などの項目を提供しますが、実際の展開処理は外部のアーカイブマネージャ GUI（`file-roller` など）を呼び出します。
   - システムに `file-roller` や、展開に必要なバックエンドコマンド（`zip`, `unzip`, `p7zip`）が不足していたため、展開が動作しませんでした。

## 変更内容

### 1. システムレベルでの Thunar 有効化 (`modules/services/desktop/niri.nix`)
- `programs.thunar.enable = true;` を追加。
- `programs.thunar.plugins` に `thunar-archive-plugin` と `thunar-volman` を追加。
- これにより、Thunar がシステムパッケージに登録され、D-Bus サービス（`org.freedesktop.FileManager1`）も適切に構成されます。

### 2. Home-manager パッケージの調整 (`modules/home/desktop/file-manager/thunar.nix`)
- システム側でインストールされるようになったため、`home.packages` から `thunar`、`thunar-archive-plugin`、`thunar-volman` を削除。
- 代わりに、アーカイブマネージャ GUI である `file-roller` と、一般的な圧縮・展開コマンド (`zip`, `unzip`, `p7zip`) を `home.packages` に追加。

### 3. XDG MIME アプリ設定の修正 (`modules/home/desktop/xdg.nix`)
- `inode/directory` のマッピング先を `org.gnome.Nautilus.desktop` から `thunar.desktop` に変更。

### 4. 評価警告の修正
- `modules/home/desktop/dev-tools/ai-tools.nix` にて、非推奨となった `pkgs.system` の参照を `pkgs.stdenv.hostPlatform.system` に修正。これに付随する `evaluation warning: 'system' has been renamed to/replaced by 'stdenv.hostPlatform.system'` の警告を解消しました。
- `hosts/torii-chan/sd-image-installer.nix` にて、SDカードインストーライメージ構築時に有効化される ZFS に対する警告を消去するため、`boot.zfs.forceImportRoot = false;` を明示的に設定しました。これで `nix flake check` における ZFS 関連の評価警告も解消されました。

### 5. Flake inputs の `follows` 設定の最適化
- キャッシュ効率、ディスク容量、整合性を考慮し、ハイブリッドな `follows` 構成を適用しました。
  - **`ghostty`, `niri`**: `follows` 設定を完全に削除。これにより、Cachix バイナリキャッシュとハッシュが完全に一致し、ローカルでのフルコンパイルを確実に回避します。
  - **`zen-browser`, `noctalia-shell`, `awww`, `spicetify-nix`, `antigravity-nix`**: follows先を安定版 `nixpkgs` (26.05) から `nixpkgs-unstable` に変更。最新のパッケージに追従しつつ、ライブラリの ABI 競合によるランタイムエラーを防ぎます。
  - **`home-manager`, `disko`, `sops-nix` などのシステム/インフラ系**: 安定版 `nixpkgs` (26.05) に `follows` を維持し、システム全体の一貫性を保ちます。

## 検証方法

1. 構文チェック:
   `nix flake check`
2. ドライ実行:
   `sudo nixos-rebuild dry-activate --flake .#BrokenPC`
3. 実機への適用 (要ユーザー承認):
   `sudo nixos-rebuild switch --flake .#BrokenPC`
4. 動作確認:
   - ブラウザから「ダウンロードしたファイルのフォルダを開く」などの操作で Thunar が起動することを確認。
   - Thunar 上で ZIP アーカイブ等を右クリックし、正常に「展開（Extract）」ができることを確認。
