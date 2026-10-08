{ config, lib, ... }:

with lib;

let
  cfg = config.my.networking.local-network;
in
{
  options.my.networking.local-network = {
    enable = mkEnableOption "Enable local network optimizations (DNS override for direct LAN connection to torii-chan)";

    toriiChanIp = mkOption {
      type = types.str;
      default = "192.168.0.128";
      description = "Local IP address of torii-chan for DNS override";
    };
  };

  config = mkIf cfg.enable {
    # Point public name directly at local IP when collocated on the same router.
    networking.hosts = {
      "${cfg.toriiChanIp}" = [ "torii-chan.t3u.uk" ];
    };

    # Prefer IPv4 in glibc address sorting (RFC 3484/6724).
    environment.etc."gai.conf".text = ''
      precedence  ::ffff:0:0/96  100
    '';
  };
}
