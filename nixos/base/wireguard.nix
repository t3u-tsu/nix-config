{ config, lib, ... }:

let
  # NixOS の wireguard モジュールがユニット名に使用するエスケープ処理
  # 公開鍵内の "/" は "-" に置換され、"+" と "=" は "\" でエスケープされる
  escape = s: lib.replaceStrings [ "+" "/" "=" ] [ "\\x2b" "-" "\\x3d" ] s;

  # networking.wireguard.interfaces からすべてのピアサービスを抽出して設定を生成
  peerServices = lib.foldl' (
    acc: ifaceName:
    let
      iface = config.networking.wireguard.interfaces.${ifaceName};
      services = lib.listToAttrs (
        map (peer: {
          name = "wireguard-${ifaceName}-peer-${escape peer.publicKey}";
          value = {
            serviceConfig = {
              Restart = "on-failure";
              RestartSec = "5s";
            };
            unitConfig.StartLimitIntervalSec = 0;
          };
        }) iface.peers
      );
    in
    acc // services
  ) { } (builtins.attrNames config.networking.wireguard.interfaces);
in
{
  # 自動的にすべての WireGuard ピアユニットにリトライ設定を適用
  systemd.services = peerServices;
}
