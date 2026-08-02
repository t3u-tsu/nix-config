# nixos/installer/wan-ip.nix - 静的 IP の設定ファイル（変数化のための差し込み口）
#
# ConoHa VPS は DHCP を提供しないため、インストーラ ISO に静的 IP を焼き込む。
# IP は `terraform apply` 後に `terraform output -json torii_chan_addresses` で
# 確定するため、このファイルの ipv4 / gateway を実 IP に置き換えてからビルドする。
#
#   - ipv4 / gateway が null のままビルドすると静的 IP は設定されない（警告が出る）。
#     その場合、ISO 起動後に VNC コンソールから手動設定できる:
#       install-nixos.sh network   （または IPV4=... GATEWAY=... install-nixos network）
#   - プレフィックス長と DNS は ConoHa の割当に合わせて変更する。
#
# このファイルは flake.nix から常に読み込まれる（ルート flake.nix に統合する場合も
# modules に含めること）。
_:

{
  conoha.installer.wan = {
    # terraform output -json torii_chan_addresses で確認した IPv4 アドレス
    ipv4 = null; # 例: "203.0.113.10"

    # ConoHa の割当に合わせて指定（通常は 24 か 32）
    prefixLength = 24;

    # デフォルトゲートウェイ（ConoHa コントロールパネル / API で確認）
    gateway = null; # 例: "203.0.113.1"

    # DNS ネームサーバー
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };
}
