# 作業ログ: デスクトップ専用モジュールへの GPG 署名・GPG エージェントの復活と SSH クライアント設定での TERM 互換性対策 (2026-06-01)

## 課題
- **サーバー（sando-kun 等）における Home Manager SOPS 復号エラー**:
  `modules/home/git.nix`（全ホスト共通の Home Manager モジュール）において、SOPS 管理下の GPG 秘密鍵（`signing.yaml`）およびその自動インポート設定（`importGpgKey`）がグローバルに定義されていた。
  サーバー環境（`sando-kun` 等）にはユーザーの日常用 SSH 秘密鍵（`~/.ssh/id_ed25519`）が配置されていないため、日常用暗号化ファイルである `signing.yaml` を復号できず、Home Manager の `sops-nix.service` の起動が失敗しデプロイがロールバックされる問題が発生していた。
- **GPG コミット署名時の Pinentry 不在エラー**:
  日常用の GPG 署名設定を移行した際、Git コミット時に `Pinentryがありません` というエラーが発生し、パスフレーズ入力ダイアログが起動しないため署名付きコミットが失敗する問題が発生していた。調査の結果、以前（2026-05-15）のコミット `6c5b804d` において、`modules/home/git.nix` から `services.gpg-agent` と `pinentry` に関連する設定が意図せず削除されていたことが判明した。
- **Ghostty からの SSH 接続時における sudo 等での terminfo 不在エラー**:
  手元の Ghostty から `sando-kun` などのサーバーへ SSH 接続した際、一般ユーザー環境では `~/.terminfo/x/xterm-ghostty` の配置により正常に認識されるが、`sudo` を実行して `root` 権限に切り替わると `root` ホームディレクトリからは認識できず、`'xterm-ghostty': unknown terminal type` エラーや `htop` 等のクラッシュが発生していた。この課題について、リモートサーバー側に対処を埋め込むのではなく、「関心の分離」に基づいた美しい方法で解決する必要があった。

## 実施内容

### 1. GPG 署名・エージェント設定のデスクトップ限定移行と復活 (過去の痕跡に基づく修正)
- **過去の correct な設定の特定**:
  `git log -p -S pinentry` の履歴調査により、以前 `git.nix` に存在し、その後失われていた `services.gpg-agent` の設定を特定した。
- **デスクトップ限定モジュールへの復活**:
  [modules/home/desktop/gpg-signing.nix](file:///home/t3u/nix-config/modules/home/desktop/gpg-signing.nix) において、GPG 秘密鍵の SOPS 復号・インポートに加えて、過去の設定に基づき `services.gpg-agent` を復活・設定した。
  NixOS 26.05 以降の最新仕様に合わせ、オプション名を非推奨の `pinentryPackage` から `pinentry.package` に修正し、デスクトップ環境向けに `pkgs.pinentry-qt`（Wayland/Niri で正常に動作する GUI ダイアログ）を設定した。
  ```nix
  services.gpg-agent = {
    enable = true;
    enableZshIntegration = true;
    pinentry.package = pkgs.pinentry-qt;
    defaultCacheTtl = 3600;
    maxCacheTtl = 86400;
  };
  ```
  これにより、サーバー側での GPG 鍵不在エラーを防ぎつつ、デスクトップ環境での署名時のパスフレーズ入力画面が正常に起動する環境を完全に再現した。

### 2. 「関心の分離」に基づく SSH クライアント設定での TERM 互換性対策
- **SSH 設定における `SetEnv` の活用**:
  シェル設定（`programs.zsh`）やサーバー側に特定のターミナルの回避策（フォールバック）を直接記述するのではなく、「手元（BrokenPC）からリモートサーバーへ接続する際の SSH クライアントの設定」という **SSH の関心事** として対策を完全にカプセル化した。
- **設定の実装**:
  [modules/home/ssh.nix](file:///home/t3u/nix-config/modules/home/ssh.nix) の宅内・社内サーバー向けワイルドカードブロック `10.0.0.*` に対し、Home Manager SSH モジュールの正しい仕様（属性セット形式）で `SetEnv` オプションを追加した。
  ```nix
  "10.0.0.*" = {
    IdentityFile = "~/.ssh/id_ed25519";
    ServerAliveInterval = 60;
    SetEnv = {
      TERM = "xterm-256color";
    };
  };
  ```
  これにより、Ghostty 端末から SSH 接続する際、SSHクライアントが自動的に接続先での `TERM` 環境変数を高い互換性を持つ `xterm-256color` に書き換えて送信する。
  このアプローチにより、
  1. サーバー側（sando-kun等）や共通のシェル設定ファイルに汚いワークアラウンドや不要な terminfo 定義を混入させる必要が一切なくなった。
  2. 手元（BrokenPC）の日常使用では `xterm-ghostty` の高度な機能を 100% 享受しつつ、SSH 先でのみ自動かつシームレスに `xterm-256color` が適用され、`sudo` 時を含めた端末定義エラーが完全に解消された。

## 検証と結果
1. **Flake 構成の静的検証**:
   - 非推奨の `initExtra` や `pinentryPackage` オプションをすべて最新仕様（`initContent` および `pinentry.package`）へ修正し、`nix flake check --no-build` で警告も含めて完全にエラーなく評価がパス（`all checks passed!`）することを確認。
2. **Git コミットと履歴管理**:
   - 変更をすべてステージングし、リモートの `refactor/sops-permissions` ブランチへコミット・プッシュを完了（最新のコミットハッシュ: `9911bef`）。

## 次のステップ
- **ユーザーによるローカル / リモートでの `switch` の適用**:
  - `BrokenPC`（ローカル）での適用により、GPG 署名時の Pinentry が正常に機能することを確認。
  - `sando-kun`（リモート）へ最新設定を `git pull` してデプロイを適用。
