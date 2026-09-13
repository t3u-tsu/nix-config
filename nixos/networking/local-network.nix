{ config, lib, ... }:

with lib;

let
  cfg = config.my.networking.local-network;
in
{
  options.my.networking.local-network = {
    enable = mkEnableOption "Enable local network optimizations (e.g. DNS overrides for NAT loopback)";

    toriiChanIp = mkOption {
      type = types.str;
      default = "192.168.0.128";
      description = "Local IP address of torii-chan for DNS override";
    };
  };

  config = mkIf cfg.enable {
    # Router has no NAT loopback, so point the public name at the LAN IP locally.
    networking.hosts = {
      "${cfg.toriiChanIp}" = [ "torii-chan.t3u.uk" ];
    };

    # Prefer IPv4 in glibc address sorting (RFC 3484/6724).
    environment.etc."gai.conf".text = ''
      precedence  ::ffff:0:0/96  100
    '';
  };
}
