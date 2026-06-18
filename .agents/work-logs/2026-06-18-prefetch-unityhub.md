# 作業ログ: Unity Hub ダウンロードエラー対策に伴う Nix ストアへのプリフェッチ

- 日付: 2026-06-18
- 作業ブランチ: `feature/fix-unityhub-download`

## 概要

`BrokenPC` システムの構築中に、Unity Hub パッケージ (`unityhub`) のソースファイル（`UnityHubSetup-3.18.0-amd64.deb`）を公式サーバーからダウンロードする際に SSL 接続エラー（unexpected eof while reading）が発生し、ビルドが停止する不具合が発生しました。
対策として、ビルド環境外で Nix ストアへ該当のソースファイルを手動でプリフェッチ（キャッシュ）し、ビルドを正常に通すようにしました。

## 課題と原因

### エラー内容:
```
curl: (56) OpenSSL SSL_read: OpenSSL/3.6.2: error:0A000126:SSL routines::unexpected eof while reading, errno 0
error: cannot download UnityHubSetup-3.18.0-amd64.deb from any mirror
```

### 原因:
Unity 公式のパッケージ配信サーバー（`hub-dist.unity3d.com`）の挙動、またはネットワーク経路における一時的・恒常的な切断により、ビルド用サンドボックス内での `curl` によるダウンロードが途中で切断されてしまっていた。

## 変更・対処内容

### 1. Nix ストアへの手動プリフェッチの実行
サンドボックス外から直接接続を行い、該当ファイルを Nix ストアに事前キャッシュしました。
```bash
nix store prefetch-file --hash-type sha256 "https://hub-dist.unity3d.com/artifactory/hub-debian-prod-local/pool/main/u/unity/unityhub_amd64/UnityHubSetup-3.18.0-amd64.deb"
```
- ダウンロード先: `/nix/store/bygkm1kaicqh0z0ibnwn3cnzn28b02bl-UnityHubSetup-3.18.0-amd64.deb`
- ハッシュ: `sha256-JDkmF8ANvW0j5L+92prUcVFqDbUGXkxxUZPjtOqwDlk=`

この対処により、`nixos-rebuild` 実行時にダウンロードがスキップされ、ローカルストアのキャッシュからビルドが進行するようになりました。

## 検証方法

1. 構文チェック:
   `nix flake check`（成功）
