# ConoHa オブジェクトストレージ（S3 互換 API）を利用した Terraform state のリモート管理
#
# 調査結果（2026-08 時点、実 API で確認済み）:
#   - ConoHa VPS 3.0 のオブジェクトストレージは Ceph RGW ベースの S3 互換 API を提供しており、
#     Terraform の backend "s3" をそのまま使用できる（2025-08 の S3 互換 API 提供開始以降）。
#   - エンドポイント: https://s3.c3j1.conoha.io（パススタイルアクセス）
#   - 認証: EC2 Credential（アクセスキー / シークレットキー）を Keystone v3 の Identity API で発行。
#     SigV4 署名、リージョンは "conoha" で署名検証に成功することを確認済み。
#   - バケット = オブジェクトストレージのコンテナ。バケット作成・バージョニング有効化も
#     S3 API で行えることを確認済み。
#
# 認証情報はハードコードせず、環境変数から読み込む:
#   AWS_ACCESS_KEY_ID     = EC2 Credential のアクセスキー
#   AWS_SECRET_ACCESS_KEY = EC2 Credential のシークレットキー
# （発行手順・前提条件は README.md の「State 管理（リモートバックエンド）」を参照）
terraform {
  backend "s3" {
    bucket = "terraform-state"   # オブジェクトストレージのコンテナ名（バケット）。事前作成が必要
    key    = "terraform.tfstate" # バケット内の state ファイルのキー
    region = "conoha"            # 署名用リージョン（ConoHa の RGW は任意リージョンの署名を受け付ける）

    # ConoHa の S3 互換エンドポイント（Ceph RGW）。仮想ホストスタイルは使えないためパススタイルにする
    endpoints = {
      s3 = "https://s3.c3j1.conoha.io"
    }
    use_path_style = true

    # ConoHa には AWS 固有のサービス（STS / IAM / EC2 メタデータ等）が存在しないため、
    # 検証・アカウント取得をスキップする
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true

    # ConoHa の RGW はアップロード時の CRC32 チェックサム（aws-sdk-go のデフォルト）を
    # 受け付けないため、チェックサム付与を無効化する（詳細は README.md）
    skip_s3_checksum = true
  }
}
