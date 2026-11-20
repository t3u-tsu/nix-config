# リポジトリ改善 TODO

保守性・拡張性・可用性向上のための未完了タスク一覧．完了項目は履歴を残さず削除する．優先度の高い順に並べる．

## 優先度 高

- BrokenPC (1 TB SSD) と x1c7 (256 GB SSD) の SSD 換装に伴う移行作業．BrokenPC の Windows と x1c7 の NixOS を移行し，停止中のタワーサーバー群へデータを退避・セットアップする．
- x1c7 の LUKS2 + TPM2 自動解錠 (`systemd-cryptenroll`) と Lanzaboote Secure Boot を導入する．SSD 換装時または換装後に実施する．
- BrokenPC, x1c7 のデータを定期バックアップする構成 (shosoin-tan への Restic 送信等) を構築する．

## 優先度 中

- shosoin-tan / torii-chan の評価とビルドをオフロードし，リモートビルドでサーバーの負荷とリソース枯渇を防ぐ．
- deploy-rs によるリモートデプロイを導入し，リモートビルドを含むデプロイ経路を統一する．
- `.internal` プライベートドメインを導入し，Nebula メッシュ上のホスト間通信 (SSH，Restic，deploy-rs，サービス間連携) の名前解決を統一・整理する．
- Attic 等のキャッシュサーバーを導入してホスト間でビルドキャッシュを共有し，ライセンス制限パッケージ用のプライベートキャッシュを運用してサーバーのビルド負荷を抑える．

## 優先度 低

- OpenTofu (`terraform/`) と Cloudflare DDNS でコード化した ConoHa VPS 構成の実機検証と，torii-chan 障害時の自動フェイルオーバーを整備する．
- kagutsuchi-sama / shosoin-tan の GPU を用い，LAN 内で共用可能なローカル LLM API サーバーを常時稼働させる (BrokenPC での `llama.cpp` PoC は検証済み)．
