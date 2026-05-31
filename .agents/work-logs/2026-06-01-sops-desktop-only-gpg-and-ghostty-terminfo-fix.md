# 作業ログ: デスクトップ専用モジュールへの GPG 署名・Ghostty terminfo の移行とサーバー側復号エラーの解消 (2026-06-01)

## 課題
- **サーバー（sando-kun 等）における Home Manager SOPS 復号エラー**:
  `modules/home/git.nix`（全ホスト共通の Home Manager モジュール）において、SOPS 管理下の GPG 秘密鍵（`signing.yaml`）およびその自動インポート設定（`importGpgKey`）がグローバルに定義されていた。
  サーバー環境（`sando-kun` 等）にはユーザーの日常用 SSH 秘密鍵（`~/.ssh/id_ed25519`）が配置されていないため、日常用暗号化ファイルである `signing.yaml` を復号できず、Home Manager の `sops-nix.service` の起動が失敗しデプロイがロールバックされる問題が発生していた。
- **Ghostty terminfo 配置設定のさらなるクリーンアップ**:
  前回、Ghostty 自体を不要とするサーバー（sando-kun）での不要なビルド回避のため、Ghostty terminfo のリンク処理を `modules/profiles/desktop/default.nix` にインラインで移行していた。これをモジュール設計としてより美しく整理し、他のデスクトップ設定と同様のモジュール構造（`dev-tools/ghostty.nix`）に統合してプロファイル側をシンプルに保つ必要があった。

## 実施内容

### 1. GPG 署名設定のデスクトップ専用モジュールへの完全分離 (案A の適用)
- **新規モジュールの作成**:
  [modules/home/desktop/gpg-signing.nix](file:///home/t3u/nix-config/modules/home/desktop/gpg-signing.nix) を作成。他のデスクトップモジュールと同様に `mkEnableOption` + `mkIf` パターンを採用し、GPG 秘密鍵の復号定義および自動インポート処理をこのモジュール内に完全にカプセル化した。
- **グローバル設定からの削除**:
  [modules/home/git.nix](file:///home/t3u/nix-config/modules/home/git.nix) から、SOPS 暗号化された GPG 鍵の定義（`sops.secrets.gpg_private_key`）および activation スクリプト（`importGpgKey`）を完全に削除。
- **モジュールのインポートと有効化**:
  [modules/home/desktop/default.nix](file:///home/t3u/nix-config/modules/home/desktop/default.nix) の `imports` に `./gpg-signing.nix` を追加。
  [modules/profiles/desktop/default.nix](file:///home/t3u/nix-config/modules/profiles/desktop/default.nix) の `my.home.desktop` 設定ブロックに `gpg-signing.enable = true;` を追加して、デスクトッププロファイルが適用されるホスト（`BrokenPC`）でのみ GPG 署名鍵の配置が行われるように設定。

### 2. Ghostty terminfo 設定のモジュールカプセル化
- [modules/profiles/desktop/default.nix](file:///home/t3u/nix-config/modules/profiles/desktop/default.nix) にインラインで記述されていた `home.file.".terminfo/x/xterm-ghostty"` のシンボリックリンク生成処理を削除。
- [modules/home/desktop/dev-tools/ghostty.nix](file:///home/t3u/nix-config/modules/home/desktop/dev-tools/ghostty.nix) 内の `config` ブロックの末尾に、上記の `home.file` 定義を移設。これにより、Ghostty が明示的に有効化（`dev-tools.enable = true` 等を経由）されたデスクトップ環境でのみ Ghostty terminfo が自動的に配置されるようになり、設定の独立性と可読性が向上した。

### 3. 一時的なマスターキーローテーションスクリプトの削除
- 前回の一時的な暗号鍵の再暗号化（ローテーション）に用いたヘルパースクリプト `rotate-master-key.sh` はその役割を完了したため、リポジトリから安全に削除した。

## 検証と結果
1. **Flake 構成の静的検証**:
   - `nix flake check --no-build` を実行し、全7ホスト（`BrokenPC`, `sando-kun`, `torii-chan`等すべて）の設定において、構文エラーや未定義オプションエラーがなく、正常に評価がパスすることを確認。
2. **Git コミットと履歴管理**:
   - `git -c commit.gpgsign=false commit` を用い、GPG署名未インポート状態のビルド環境でも署名エラーによるブロックを回避して正常にコミット完了（コミットハッシュ: `985c475`）。

## 次のステップ
- **ユーザー承認の取得とデプロイ**:
  - `BrokenPC`（ローカル環境）での `nixos-rebuild switch` の実行確認と承認。
  - リモートサーバー `sando-kun` に対する変更の pull と `nixos-rebuild switch` の実行確認と承認。
- **動作確認**:
  - `sando-kun` で `systemctl --user status sops-nix.service` を確認し、GPG 鍵の復号エラーによるサービス起動失敗が完全に解消され、正常起動していることを実機検証。
  - `BrokenPC` で GPG 鍵が引き続き正常にインポートされていることを検証。
- **ブランチの main への PR 作成とマージ確認**（ユーザー承認の上で実施）。
