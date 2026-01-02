{ config, lib, ... }:

with lib;

let
  cfg = config.my.localNetwork;
in {
  options.my.localNetwork = {
    enable = mkEnableOption "Enable local network optimizations (e.g. DNS overrides for NAT loopback)";

    toriiChanIp = mkOption {
      type = types.str;
      default = "192.168.0.128";
      description = "Local IP address of torii-chan for DNS override";
    };
  };

  config = mkIf cfg.enable {
    # Resolve torii-chan.t3u.uk to its LAN IP when in the same network
    # This bypasses NAT loopback issues.
    networking.hosts = {
      "${cfg.toriiChanIp}" = [ "torii-chan.t3u.uk" ];
    };
  };
}
