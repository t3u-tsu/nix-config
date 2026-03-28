# 作業ログ: SOPS 権限・復号問題の解決 (2026-03-29)

## 課題
ユーザ `t3u` が `.sops.yaml` に鍵を追加したにもかかわらず、手動で `secrets/secrets.yaml` を復号できない。
原因調査の結果、直近のコミット（e8aaad3）で追加された環境変数 `SOPS_AGE_SSH_PRIVATE_KEY_FILE` が非標準であり、`sops` バイナリに認識されていないこと、および `SOPS_AGE_KEY_FILE` が権限のないシステム鍵を指していることが判明した。

## 実施内容

### 1. 依存パッケージの追加
- `modules/packages/security.nix` に `ssh-to-age` を追加。

### 2. SOPS 設定の修正
- `modules/core/sops.nix` を修正：
    - `sops.age.sshKeyPaths` にユーザの SSH 鍵を追加し、`sops-nix` が正しく鍵を統合（root 権限での復号用）できるようにした。
    - 非標準の環境変数 `SOPS_AGE_SSH_PRIVATE_KEY_FILE` を削除。

### 3. ユーザ利便性の向上 (自動復号エイリアス)
- `modules/home/cli-tools.nix` に `sops` のエイリアスを追加：
    - `alias sops="SOPS_AGE_KEY=\$(ssh-to-age -private-key -i ~/.ssh/id_ed25519) sops"`
    - これにより、実行時に SSH 鍵から age 鍵を動的に抽出して環境変数にセットする。

## 検証
手動でのシミュレーションにより、エイリアス相当のコマンドで `secrets/secrets.yaml` の復号（読み取り）ができることを確認済み。

## 次のステップ
- `nixos-rebuild switch --flake .#BrokenPC` を実行して設定を反映。
