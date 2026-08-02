# nixos/installer/network.nix - インストーラ ISO のネットワーク設定
#
# ConoHa VPS は DHCP を提供しないため、静的 IP を明示設定する。
# IP は `terraform apply` 後に確定する（terraform/outputs.tf の
# torii_chan_addresses を参照）。ISO ビルド時点で未確定なら
# conoha.installer.wan.ipv4 = null のままビルドし、起動後に
# `install-nixos.sh network` で手動設定するフォールバックを用意する。
#
# 標準のインストーラ ISO（installation-device.nix）は NetworkManager を
# 有効化するが、DHCP のない ConoHa では無意味なため無効化し、
# リポジトリ既存ホスト（hosts/torii-chan 等）と同じ「スクリプト式ネットワーク +
# 静的 IP」方式に統一する。
{
  config,
  lib,
  ...
}:

let
  cfg = config.conoha.installer;
in
{
  config = {
    networking = {
      # スクリプト式ネットワーク（systemd-networkd / NetworkManager は使わない）
      useDHCP = false;
      # virtio NIC を eth0 として扱う（systemd の予測可能な命名を無効化）
      usePredictableInterfaceNames = false;
      networkmanager.enable = lib.mkForce false; # installation-device.nix が有効化するため mkForce で無効化

      # 静的 IP 設定（wan.ipv4 が指定された場合のみ有効）
      interfaces.${cfg.interface} = lib.mkIf (cfg.wan.ipv4 != null) {
        useDHCP = false;
        ipv4.addresses = [
          {
            address = cfg.wan.ipv4;
            prefixLength = cfg.wan.prefixLength;
          }
        ];
      };

      defaultGateway = lib.mkIf (cfg.wan.gateway != null) cfg.wan.gateway;
      nameservers = cfg.wan.nameservers;

      # インストーラはパブリック IP に直接晒されるため、22/tcp のみ開放する
      firewall = {
        enable = true;
        allowedTCPPorts = [ 22 ];
        logRefusedConnections = false;
      };
    };

    # 静的 IP 未指定時のビルド時警告（VNC コンソールからの手動設定が必要になる旨）
    warnings = lib.optional (cfg.wan.ipv4 == null) ''
      conoha.installer.wan.ipv4 が未設定です。この ISO は静的 IP が設定されないため、
      SSH 接続には起動後に VNC コンソールから次を実行してネットワークを設定してください:
        install-nixos.sh network
      または、terraform apply 後に IP を確定してから ISO をビルドし直してください。
    '';
  };
}
