#!/usr/bin/env bash
# install-nixos - ConoHa VPS（512MB）への NixOS インストール補助スクリプト
#
# インストーラ ISO（nixos/installer/default.nix）に同梱され、SSH セッションから
# nixos-install を非対話で実行するために使う。
#
# 使い方（ISO 起動後の root シェルで実行）:
#   install-nixos network  ネットワークを手動設定する
#                          （静的 IP が ISO に焼き込まれていない場合のフォールバック）
#   install-nixos install  ディスク分割 → フォーマット → swap → nixos-install を一括実行
#                          ※ ディスクを消去するため INSTALL_YES=1 の指定が必須
#   install-nixos status   現在のネットワーク / メモリ / ディスク状態を表示
#
# 環境変数（すべて任意。デフォルト値あり）:
#   IFACE            ネットワークインターフェース名（デフォルト: eth0）
#   IPV4             IPv4 アドレス（例: 203.0.113.10）
#   PREFIX           IPv4 プレフィックス長（デフォルト: 24）
#   GATEWAY          デフォルトゲートウェイ
#   NAMESERVERS      スペース区切りの DNS（デフォルト: 1.1.1.1 8.8.8.8）
#   DISK             インストール先ディスク（デフォルト: /dev/vda）
#   SWAP_SIZE        作成する swap ファイルのサイズ（デフォルト: 1G）
#   NIXOS_HOSTNAME   ターゲットのホスト名（デフォルト: conoha-vps）
#   SSH_PUBLIC_KEYS  authorizedKeys に登録する公開鍵
#                    （1 行 1 鍵。デフォルト: t3u の公開鍵）
#
# 注意:
#   - 認証情報・秘密鍵はハードコードしない（公開鍵のみ）
#   - このスクリプト自体はターゲットの設定を作り込むための「最小テンプレート」。
#     リポジトリの flake 設定をインストールしたい場合は、クロージャを ISO に
#     含める（isoImage.storeContents）か、nixos-install --flake を使用する
#     （詳細は docs/conoha-vps-installer-iso.md）
set -euo pipefail

IFACE="${IFACE:-eth0}"
IPV4="${IPV4:-}"
PREFIX="${PREFIX:-24}"
GATEWAY="${GATEWAY:-}"
NAMESERVERS="${NAMESERVERS:-1.1.1.1 8.8.8.8}"
DISK="${DISK:-/dev/vda}"
SWAP_SIZE="${SWAP_SIZE:-1G}"
NIXOS_HOSTNAME="${NIXOS_HOSTNAME:-conoha-vps}"
SSH_PUBLIC_KEYS="${SSH_PUBLIC_KEYS:-ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3QNRSxPauISsWs7nob0tXfxjTsMpBEIYIjasRD9bpT t3u@BrokenPC}"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

# --- network: 静的 IP を手動設定する（フォールバック） ------------------------
cmd_network() {
  [ -n "$IPV4" ] || die "IPV4 が未設定です。例: IPV4=203.0.113.10 GATEWAY=203.0.113.1 install-nixos network"
  [ -n "$GATEWAY" ] || die "GATEWAY が未設定です。"

  echo "==> インターフェース確認: $IFACE"
  ip link show "$IFACE" >/dev/null 2>&1 \
    || die "インターフェース $IFACE が見つかりません（ip link で実名を確認してください）"

  echo "==> 静的 IP 設定: $IPV4/$PREFIX"
  ip addr flush dev "$IFACE"
  ip addr add "$IPV4/$PREFIX" dev "$IFACE"
  ip link set "$IFACE" up

  echo "==> デフォルトルート設定: via $GATEWAY"
  # ゲートウェイが同一サブネットに存在しない場合（onlink 構成）も試行する
  ip route replace default via "$GATEWAY" dev "$IFACE" onlink \
    || die "デフォルトルートを設定できませんでした"

  echo "==> DNS 設定"
  : > /etc/resolv.conf
  for ns in $NAMESERVERS; do
    echo "nameserver $ns" >> /etc/resolv.conf
  done

  echo "==> 疎通確認"
  if ping -c 1 -W 3 1.1.1.1 >/dev/null 2>&1; then
    echo "OK: インターネット疎通あり"
  else
    echo "注意: 1.1.1.1 への ping に失敗しました（ネットワーク構成を確認してください）"
  fi
  echo "==> ネットワーク設定完了"
}

# --- status: 現在の状態を表示する ---------------------------------------------
cmd_status() {
  echo "==> インターフェース / IP"
  ip -brief addr 2>/dev/null || ip addr
  echo ""
  echo "==> ルーティング"
  ip route
  echo ""
  echo "==> メモリ / swap"
  free -h
  echo ""
  echo "==> zram"
  zramctl 2>/dev/null || echo "zram は使用不可です"
  echo ""
  echo "==> ディスク"
  lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
}

# --- install: ディスク分割 → フォーマット → swap → nixos-install --------------
cmd_install() {
  [ "${INSTALL_YES:-}" = "1" ] \
    || die "ディスク $DISK を消去します。実行する場合は INSTALL_YES=1 を指定してください"

  [ -b "$DISK" ] || die "ディスクが見つかりません: $DISK（lsblk でデバイス名を確認してください）"
  ROOT_PART="${DISK}1"

  echo "==> パーティション作成（MBR / BIOS ブート）: $DISK"
  parted -s "$DISK" mklabel msdos
  parted -s "$DISK" mkpart primary ext4 1MiB 100%
  parted -s "$DISK" set 1 boot on
  partprobe "$DISK"
  sleep 2 # カーネルが新パーティションを認識するのを待つ

  echo "==> フォーマット: $ROOT_PART (ext4)"
  mkfs.ext4 -F -L nixos "$ROOT_PART"

  echo "==> /mnt にマウント"
  mount "$ROOT_PART" /mnt

  echo "==> swap ファイル作成: /mnt/swapfile (${SWAP_SIZE})"
  # ターゲットの swap ファイルを兼ねつつ、ライブ環境（tmpfs の /nix/store）の
  # メモリ不足も吸収するため、nixos-install 前に swapon しておく
  fallocate -l "$SWAP_SIZE" /mnt/swapfile
  chmod 600 /mnt/swapfile
  mkswap /mnt/swapfile
  swapon /mnt/swapfile

  echo "==> ハードウェア設定の生成（nixos-generate-config）"
  nixos-generate-config --root /mnt

  echo "==> configuration.nix の作成"
  write_configuration

  echo "==> nixos-install 実行（root パスワードは設定しない。SSH 鍵でログイン）"
  nixos-install --no-root-passwd --root /mnt

  echo ""
  echo "==> インストール完了。次の手順:"
  echo "    1. swap を無効化してディスクをアンマウント"
  echo "       swapoff /mnt/swapfile && umount /mnt"
  echo "    2. ローカルマシンで ISO を排出して再起動"
  echo "       ./terraform/scripts/nixos-iso.sh eject <instance_id>"
}

# --- configuration.nix を生成する（install から呼ばれる） ----------------------
write_configuration() {
  # authorizedKeys の Nix リスト文字列を組み立てる（1 行 1 鍵）
  local nix_keys=""
  while IFS= read -r key; do
    [ -n "$key" ] && nix_keys="${nix_keys} \"${key}\""
  done <<< "${SSH_PUBLIC_KEYS}"

  # nameservers の Nix リスト文字列を組み立てる
  local nix_ns=""
  for ns in $NAMESERVERS; do
    nix_ns="${nix_ns} \"${ns}\""
  done

  cat > /mnt/etc/nixos/configuration.nix <<EOF
# ConoHa VPS 向けの最小 NixOS 設定（install-nixos.sh が生成）
{
  imports = [
    ./hardware-configuration.nix
  ];

  # GRUB（BIOS / MBR）
  boot.loader.grub = {
    enable = true;
    devices = [ "${DISK}" ];
  };

  networking.hostName = "${NIXOS_HOSTNAME}";
  networking.usePredictableInterfaceNames = false; # virtio NIC を eth0 として使う

  # ConoHa VPS は DHCP を提供しないため静的 IP を設定する
  networking.useDHCP = false;
  networking.interfaces.eth0.ipv4.addresses = [
    { address = "${IPV4}"; prefixLength = ${PREFIX}; }
  ];
  networking.defaultGateway = "${GATEWAY}";
  networking.nameservers = [${nix_ns} ];

  # SSH（root は公開鍵のみでログイン）
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };
  users.users.root.openssh.authorizedKeys.keys = [${nix_keys} ];

  # インストール時に作成した swap ファイルを有効化
  swapDevices = [
    { device = "/swapfile"; }
  ];

  system.stateVersion = "26.05";
}
EOF

  echo "    生成された設定: /mnt/etc/nixos/configuration.nix"
  sed -n '1,60p' /mnt/etc/nixos/configuration.nix
}

# --- メイン --------------------------------------------------------------------
cmd="${1:-help}"
case "${cmd}" in
  network)
    cmd_network
    ;;
  install)
    cmd_install
    ;;
  status)
    cmd_status
    ;;
  help | -h | --help)
    cat <<'HELP'
install-nixos - ConoHa VPS（512MB）への NixOS インストール補助スクリプト

使い方:
  install-nixos network  ネットワークを手動設定する
                        （静的 IP が ISO に焼き込まれていない場合のフォールバック）
  install-nixos install  ディスク分割 → フォーマット → swap → nixos-install を一括実行
                        ※ ディスクを消去するため INSTALL_YES=1 の指定が必須
  install-nixos status   現在のネットワーク / メモリ / ディスク状態を表示

環境変数（すべて任意。デフォルト値あり）:
  IFACE            ネットワークインターフェース名（デフォルト: eth0）
  IPV4             IPv4 アドレス（例: 203.0.113.10）
  PREFIX           IPv4 プレフィックス長（デフォルト: 24）
  GATEWAY          デフォルトゲートウェイ
  NAMESERVERS      スペース区切りの DNS（デフォルト: 1.1.1.1 8.8.8.8）
  DISK             インストール先ディスク（デフォルト: /dev/vda）
  SWAP_SIZE        作成する swap ファイルのサイズ（デフォルト: 1G）
  NIXOS_HOSTNAME   ターゲットのホスト名（デフォルト: conoha-vps）
  SSH_PUBLIC_KEYS  authorizedKeys に登録する公開鍵（1 行 1 鍵）

詳細: docs/conoha-vps-installer-iso.md
HELP
    ;;
  *)
    echo "usage: install-nixos {network|install|status|help}" >&2
    exit 1
    ;;
esac
