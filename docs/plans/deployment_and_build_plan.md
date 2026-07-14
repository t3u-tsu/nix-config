# デプロイ・ビルドシステム統合計画書（改訂版）

## 1. 目的
SBC（`torii-chan`）でのビルド負荷をゼロにしつつ、安全（自動ロールバック）かつ高速なデプロイと、unfreeパッケージを含むプライベートキャッシュ環境を構築する。

## 2. 採用ツール
| ツール | 役割 |
| :--- | :--- |
| **`deploy-rs`** | SSH疎通・ヘルスチェック付きの自動ロールバック（Magic Rollback） |
| **`Attic`** | JWT認証付きプライベートバイナリキャッシュ（unfree保護） |
| **GitHub Actions (Self-Hosted)** | タワーサーバー（`shosoin-tan`）での安全な自動更新ビルド |

## 3. 重要対策（必須実装）
1. **GCとロールバックの競合回避**: NixOSの自動GCは `--delete-older-than 30d` 等に制限し、`deploy-rs` が管理するプロファイルパスが削除されないよう保護する。
2. **Atticへの自動キャッシュ登録**: 開発PCでのビルド時に `post-build-hook` を設定し、`attic push` を自動実行してキャッシュの断絶を防ぐ。
3. **デプロイ時のヘルスチェック強化**: `deploy-rs` の `check` オプションに、SSH接続だけでなく「SBCから外部への通信（例: ping 1.1.1.1）」を確認するカスタムコマンドを追加し、半文鎮状態を検知する。
4. **シークレット管理**: AtticのJWTトークンは `sops-nix` で暗号化管理し、Gitへの平文コミットを避ける。

## 4. 実装ロードマップ
- **Phase 1: タワーサーバー (`shosoin-tan`)**
  - `boot.binfmt.emulatedSystems = [ "aarch64-linux" ]` の有効化
  - `services.atticd` の構築とリポジトリ作成
  - `services.github-runners` の設定
- **Phase 2: 開発PC (`BrokenPC`) & Flake**
  - `flake.nix` に `deploy-rs` 出力を定義
  - `nix.buildMachines` に `shosoin-tan` を登録
  - `post-build-hook` による `attic push` の自動化設定
- **Phase 3: ターゲット (`torii-chan`)**
  - `sops-nix` でAtticトークンを配布
  - `require-sigs = true` とAtticを `substituters` に設定し、ローカルビルドを禁止
  - `comin` を無効化し、`deploy-rs` へ完全移行

## 5. アーキテクチャ概要
```mermaid
flowchart TD
    DevPC[開発PC] -- "1. リモートビルド / post-build-hook" --> Tower
    GHA[GHA] -- "2. ジョブ委託" --> Tower
    
    subgraph Tower[タワーサーバー: shosoin-tan]
        Attic[Attic キャッシュ]
        Runner[Self-Hosted Runner]
        Builder[Nix デーモン (x86_64 & aarch64)]
    end
    
    Builder --> Attic
    Runner --> Builder
    
    DevPC -- "3. deploy-rs (ヘルスチェック付き)" --> SBC[SBC: torii-chan]
    SBC -- "4. 署名付きバイナリ取得" --> Attic
    sops[sops-nix] -. "トークン配布" .-> SBC
```

