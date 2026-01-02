# NixOS設定構築 of torii-chan

## 目的

Orange Pi Zero3 (`torii-chan`) 向けのNixOS設定を構築し、SD運用からHDD運用への移行準備を完了する。

## 現在の状況 (2026-01-02)

**torii-chan: Coordinated Update Hubとして稼働中。10.0.1.1:8080 (App) / 10.0.0.1:8080 (Mgmt) でステータスを提供。**

**kagutsuchi-sama: Coordinated Update Producerとして稼働中。毎日04:00にシステム・プラグインを更新しHubへ通知。**

**ビルド環境: Arch Linuxホストでaarch64エミュレーションビルドを確立。公式キャッシュの利用によりビルド時間が劇的に短縮。**

### 達成したマイルストーン

1.  **WireGuard (wg0)**: 管理用ネットワーク (10.0.0.0/24) を構築。全ホストでSSHをこのインターフェースのみに制限。
...
27. 自動更新システムの高度化: `pushChanges` フラグを導入し、更新・プッシュ担当（Producer）と適用担当（Consumer）を分離。また、`nvfetcher` タスクをサービス側から動的に登録する構成にリファクタリングし、ホスト間の移動や拡張性を向上。
28. Nix設定の共通化と集約: `common/nix.nix` を新設し、実験的機能、バイナリキャッシュ、`trusted-users` 設定を一括管理。各ホストからの重複設定を排除。
29. aarch64ビルドの最適化: `torii-chan` のビルドをクロスコンパイルからエミュレーションベースのネイティブビルドに移行。`binfmt` と `extra-platforms` 設定により、x86_64ホスト上で公式のaarch64バイナリキャッシュを利用可能にした。
30. Coordinated Update Hubの完全稼働: `torii-chan` で `update-hub` を稼働させ、ファイアウォール設定（wg0/wg1）を最適化して外部・内部からのステータス確認を可能にした。

### 次のステップ

1.  **shosoin-tan 実機確認**: モニターアダプタ入手後、ディスクの `by-id` を確認し Disko 設定を最適化、インストール実施。
2.  **共通設定の拡充**: シェルの設定 (zsh/fish) や alias など、全ホストで共通化したい設定を `common/` に追加していく。
3.  **自動更新ログの通知**: 更新失敗時に Discord 等へ通知する仕組みの検討。

### 運用ルール (開発ワークフロー)

- **文書管理**: トップレベルの `README` を整理する際は、ホスト一覧や全体構造などの「プロジェクト俯瞰に必要な共通概要事項」を削除しないこと。詳細はサブディレクトリの `README` に任せつつ、全体像はトップレベルで維持し、各所への誘導を行う。
- 変更後は必ず `nix flake check` を実行し、構文エラーがないか確認する。
- ホスト追加や重要な変更の際は、`GEMINI.md` および `README.md` (日/英) を更新する。
- 変更はこまめに git commit する。

### 主要コマンド

- torii-chan デプロイ: `nix run nixpkgs#nixos-rebuild -- switch --flake .#torii-chan --target-host t3u@10.0.0.1 --sudo --ask-sudo-password`
- kagutsuchi-sama デプロイ: `nix run nixpkgs#nixos-rebuild -- switch --flake .#kagutsuchi-sama --target-host t3u@10.0.0.3 --sudo --ask-sudo-password`
- shosoin-tan チェック: `nix flake check`
- 秘密情報の編集: `nix shell nixpkgs#sops -c sops secrets/secrets.yaml`
