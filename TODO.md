# リポジトリ改善 TODO

保守性・拡張性・可用性向上のための未完了タスク一覧．完了項目は履歴を残さず削除する．

- shosoin-tan / torii-chan の評価とビルドをメインマシン (BrokenPC)へオフロード，またはリモートビルドを構築してサーバーの負荷とリソース枯渇 (D-Bus タイムアウト等)を防ぐ．シェル設定も軽量化する．
- Attic 等のキャッシュサーバーを導入してホスト間でビルドキャッシュを共有し，ライセンス制限パッケージ用のプライベートキャッシュを運用してサーバーのビルド負荷を抑える．
- リモートサーバーでの重いビルドを回避するため，deploy-rs またはキャッシュベースの pull 方式を選定・導入する (`comin` は削除済み)．
- OpenTofu (`terraform/`)と Cloudflare DDNS でコード化した ConoHa VPS 構成の実機検証と，torii-chan 障害時の自動フェイルオーバーを整備する．
- BrokenPC のデータを定期バックアップする構成 (shosoin-tan への Restic 送信等)を構築する．
- kagutsuchi-sama / shosoin-tan の GPU を用い，LAN 内で共用可能なローカル LLM API サーバーを常時稼働させる (BrokenPC での `llama.cpp` PoC は検証済み)．
