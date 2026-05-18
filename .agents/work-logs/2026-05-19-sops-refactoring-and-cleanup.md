# 作業ログ: SOPS 権限管理のリファクタリングと監視機能の削除 (2026-05-19)

## 課題
- `secrets/secrets.yaml` にすべての秘密情報が集中しており、全ホストがすべての情報を復号できる状態だった。
- 監視サービス（Grafana/Prometheus）が不要になったため、関連設定と秘密情報のクリーンアップが必要だった。
- ユーザーのGPG署名鍵がシステムレベルで配布されており、セキュリティ境界が曖昧だった。

## 実施内容

### 1. 監視機能の完全削除
- `modules/services/monitoring/` ディレクトリを削除。
- `hosts/torii-chan/configuration.nix` および `modules/services/default.nix` からのインポート・設定を削除。
- 関連する秘密情報（`grafana_admin_password`）を削除対象として整理。

### 2. SOPS 権限管理の刷新（最小権限モデル）
- **ディレクトリ構造の変更**:
    - `secrets/hosts/`: 各ホスト固有の情報を格納。
    - `secrets/services/`: 特定のサービス（Minecraft, Backup等）に関連する情報を格納。
    - `secrets/common.yaml`: 全ホストで必要な最小限の情報。
- **`.sops.yaml` の再定義**:
    - マスターキー（オフライン管理推奨）を導入。
    - ホスト固有ファイルは「マスター + 該当ホストのSSHホスト鍵」でのみ復号可能に制限（ユーザー鍵も除外）。
    - サービス・共通ファイルは「マスター + ユーザー鍵 + 関連ホスト鍵」で管理。
- **復号プロセスの修正 (`modules/core/sops.nix`)**:
    - 復号鍵をユーザーの `id_ed25519` から、システムの `/etc/ssh/ssh_host_ed25519_key` を参照するように変更。
    - ホスト名に基づき、自動的に `secrets/hosts/${hostname}.yaml` をデフォルトの秘密情報ファイルとして読み込むように設定。

### 3. ユーザー環境の最適化
- **GPG署名鍵のHome Manager移行**:
    - システムレベルの配布を廃止し、`sops-nix` の Home Manager モジュールを利用。
    - ユーザー鍵を持つマシンでのみ、ユーザーのホームディレクトリ配下に展開・インポートされる構成に変更。
- **エイリアスの整理**:
    - `cli-tools.nix` にあった、ユーザー鍵の使用を強制する `sops` エイリアスを削除。

### 4. 不要な秘密情報の削除
- `github_token`: システム内での参照が確認できず、Actions等とも無関係なため削除。

## 構造
- ブランチ: `refactor/sops-permissions` (リモートへプッシュ済み)

## 次のステップ（ユーザー作業）
1. **公開鍵の更新**: `.sops.yaml` 内のプレースホルダーを実際の公開鍵に置換。
    - マスターキー生成: `age-keygen`
    - ホスト鍵取得: `ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub`
2. **秘密情報の移行**: 既存の `secrets/secrets.yaml` から新しいディレクトリ構造の各ファイルへデータを移動。
3. **検証**: 各ホストで `nixos-rebuild dry-activate` 等を行い、自身の秘密情報が正しく復号できるか確認。
